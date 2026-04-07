'use strict';
import * as express from 'express';
import * as CompetitionQueries from '../sql/competitions.queries';
import * as UserQueries from '../sql/users.queries';
import * as OAuthQueries from '../sql/oauth.queries';
import { sendPushNotifications } from '../utilities/apnsHelper';
import { CompetitionState } from '../utilities/enums/CompetitionState';
import { handleError } from '../utilities/errorHelpers';
import * as UserHelpers from '../utilities/userHelpers';
import { getCompetitionStandings } from '../utilities/competitionStandingsHelper';
import * as cryptoHelpers from '../utilities/cryptoHelpers';
import { v4 as uuid } from 'uuid';

const router = express.Router();

router.post('/createPublicCompetition', function (req, res) {
    const startDate = new Date(req.body['startDate']);
    const endDate = new Date(req.body['endDate']);
    const displayName: string = req.body['displayName'];
    const timezone: string = req.body['ianaTimezone'];
    const adminUserId: string = req.body['adminUserId'];

    if (!startDate || !endDate || !displayName || !timezone || !adminUserId) {
        handleError(null, 400, 'Missing required parameter', res);
        return;
    }

    if (displayName.length > 255) {
        handleError(null, 400, 'Display name is too long', res);
        return;
    }

    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
        handleError(null, 400, 'Invalid date format', res);
        return;
    }

    if (endDate < new Date()) {
        handleError(null, 400, 'End date must be in the future', res);
        return;
    }

    const msPerDay = 1000 * 60 * 60 * 24;
    const maxCompetitionLengthInMs = 30 * msPerDay;
    const competitionLengthInMs = endDate.getTime() - startDate.getTime();
    if (competitionLengthInMs < msPerDay || competitionLengthInMs > maxCompetitionLengthInMs) {
        handleError(null, 400, 'Competition length must be between 1 and 30 days', res, true);
        return;
    }

    const startDateUTC = new Date(startDate.toUTCString());
    const endDateUTC = new Date(endDate.toUTCString());
    const accessToken = cryptoHelpers.getRandomToken();
    const competitionId = uuid();

    CompetitionQueries.createPublicCompetition({
        startDate: startDateUTC,
        endDate: endDateUTC,
        displayName,
        adminUserId: UserHelpers.convertUserIdToBuffer(adminUserId),
        accessToken,
        ianaTimezone: timezone,
        competitionId
    })
        .then((_result) => {
            res.json({ 'competition_id': competitionId });
        })
        .catch(error => {
            handleError(error, 500, 'Error creating public competition', res);
        });
});

router.post('/performDailyTasks', async function (req, res) {
    let taskResults: { name: string; result: string }[] = [];
    let errors: [taskName: string, error: Error][] = [];

    // Optional currentDate override — allows callers (e.g. tests) to specify what
    // "now" means for this run without restarting the server.
    const now = req.body['currentDate'] ? new Date(req.body['currentDate']) : new Date();

    const deleteExpiredTokensPromise = deleteExpiredRefreshTokens(now);

    // Do not parallelize the competition tasks
    // because we do not want to move a competition to processing to archiving in the same run
    // This should not happen but could happen if the cron job has not been run recently
    try {
        taskResults.push({ name: 'archiveCompetitions', result: await archiveCompetitions(now) });
    } catch (err) {
        errors.push(['archiveCompetitions', err]);
    }

    try {
        taskResults.push({ name: 'processRecentlyEndedCompetitions', result: await processesRecentlyEndedCompetitions(now) });
    } catch (err) {
        errors.push(['processRecentlyEndedCompetitions', err]);
    }

    try {
        taskResults.push({ name: 'deleteExpiredRefreshTokens', result: await deleteExpiredTokensPromise });
    } catch (err) {
        errors.push(['deleteExpiredRefreshTokens', err]);
    }

    try {
        taskResults.push({ name: 'createWeeklyPublicCompetition', result: await createWeeklyPublicCompetition(now) });
    } catch (err) {
        errors.push(['createWeeklyPublicCompetition', err]);
    }

    const summary = {
        tasks: taskResults,
        errors: errors.map(([name, error]) => ({ name, error: error.message }))
    };

    if (errors.length > 0) {
        console.error('Error performing daily tasks:', summary);
        return res.status(500).json(summary);
    } else {
        console.log('Daily tasks completed:', summary);
        return res.status(200).json(summary);
    }
});

// Get recently ended competitions
// Move them to the processing state
// Send push notifications to users
async function processesRecentlyEndedCompetitions(now: Date): Promise<string> {
    const competitionsToMoveToProcessing = await CompetitionQueries.getCompetitionsInState({
        state: CompetitionState.NotStartedOrActive,
        finishedBeforeDate: now
     });

     // Update competitions to processing state
     await Promise.all(competitionsToMoveToProcessing.map(competition => {
         return CompetitionQueries.updateCompetitionState({ competitionId: competition.competition_id, newState: CompetitionState.ProcessingResults });
     }));

     if (competitionsToMoveToProcessing.length === 0) {
        return 'No competitions to process';
     }

     // For each competition, get the users and send a notification
     const notifications = [];
     for (const competition of competitionsToMoveToProcessing) {
         const users = await CompetitionQueries.getUsersForCompetition({ competitionId: competition.competition_id });
         for (const user of users) {
             notifications.push({
                 userId: UserHelpers.convertBufferToUserId(user.user_id),
                 title: `The competition "${competition.display_name}" has ended!`,
                 body: 'The final results are being processed and will be posted tomorrow',
             });
         }
     }

     if (notifications.length > 0) {
         await sendPushNotifications(notifications);
     }

     return `Moved ${competitionsToMoveToProcessing.length} competition(s) to processing state`;
}

// Get competitions that have been in the processing state for more than 24 hours
// Move them to the archived state and archive results
// Send final results push notifications
async function archiveCompetitions(now: Date): Promise<string> {
    const olderThan24Hrs = new Date(now.getTime() - (24 * 60 * 60 * 1000));
     const competitionsToArchive = await CompetitionQueries.getCompetitionsInState({
        state: CompetitionState.ProcessingResults,
        finishedBeforeDate: olderThan24Hrs
     });

    if (competitionsToArchive.length === 0) {
        return 'No competitions to archive';
    }

    // Calculate the final results for each competition
    for (const competition of competitionsToArchive) {
        try {
            const competitionUsers = await CompetitionQueries.getUsersForCompetition({ competitionId: competition.competition_id });

            if (competitionUsers.length === 0) {
                console.log(`No users found for competition ${competition.competition_id}. Skipping.`);
                continue;
            }

            const competitionResults = await getCompetitionStandings(
                competition,
                competitionUsers.map(user => ({
                    userId: UserHelpers.convertBufferToUserId(user.user_id),
                    first_name: null,
                    last_name: null,
                    finalPoints: user.final_points
                })),
                competition.iana_timezone);

            // Send final results push notifications
            // Sort users by most points to fewest
            const sortedResults = Object.values(competitionResults).sort((a, b) => b.activityPoints - a.activityPoints);
            const notifications = [];
            for (let i = 0; i < sortedResults.length; i++) {
                const userPoints = sortedResults[i];
                let place: string;
                switch (i) {
                    case 0:
                        place = 'first';
                        break;
                    case 1:
                        place = 'second';
                        break;
                    case 2:
                        place = 'third';
                        break;
                    default:
                        place = `${i + 1}th`;
                }
                notifications.push({
                    userId: userPoints.userId,
                    title: `The competition "${competition.display_name}" has ended!`,
                    body: `You came in ${place} place with ${userPoints.activityPoints} points!`,
                });
            }

            // Send push notifications
            const pushNotificationsPromise = sendPushNotifications(notifications);

            // Set final results in the UsersCompetitions table
            await Promise.all(Object.values(competitionResults).map(userPoints => {
                return CompetitionQueries.updateCompetitionFinalPoints({
                    userId: UserHelpers.convertUserIdToBuffer(userPoints.userId),
                    competitionId: competition.competition_id,
                    finalPoints: userPoints.activityPoints
                });
            }));

            await pushNotificationsPromise;
        } catch (err) {
            // Log the error but continue processing other competitions
            console.error(`Error calculating final results for competition ${competition.competition_id}:`, err);
        }
    }
    
    // Update competitions to archived state
    await Promise.all(competitionsToArchive.map(competition => {
        return CompetitionQueries.updateCompetitionState({ competitionId: competition.competition_id, newState: CompetitionState.Archived });
    }));

    return `Archived ${competitionsToArchive.length} competition(s)`;
}

async function deleteExpiredRefreshTokens(now: Date): Promise<string> {
    await OAuthQueries.deleteExpiredRefreshTokens({ currentDate: now });
    return 'Deleted expired refresh tokens';
}

function getNextMondayStartDate(from: Date): Date {
    const dayOfWeek = from.getUTCDay(); // 0=Sun, 1=Mon, ..., 6=Sat
    const daysUntilMonday = dayOfWeek === 1 ? 0 : (8 - dayOfWeek) % 7;
    const monday = new Date(from);
    monday.setUTCDate(from.getUTCDate() + daysUntilMonday);
    monday.setUTCHours(0, 0, 0, 0);
    return monday;
}

async function createWeeklyPublicCompetition(now: Date): Promise<string> {
    const dayOfWeek = now.getUTCDay();

    // Only create on Sunday (preview day) or Monday (fallback if Sunday task failed)
    if (dayOfWeek !== 0 && dayOfWeek !== 1) {
        return 'Skipped: not Sunday or Monday';
    }

    const upcomingMonday = getNextMondayStartDate(now);

    // Check if a competition for the upcoming week already exists
    const activePublicCompetitions = await CompetitionQueries.getPublicCompetitions({
        activeState: CompetitionState.NotStartedOrActive
    });
    const alreadyScheduled = activePublicCompetitions.some(c =>
        new Date(c.start_date).getTime() >= upcomingMonday.getTime()
    );
    if (alreadyScheduled) {
        return 'Skipped: competition for upcoming week already exists';
    }

    const adminUserId = process.env.FWF_SYSTEM_ADMIN_USER_ID;
    if (!adminUserId) {
        throw new Error('FWF_SYSTEM_ADMIN_USER_ID environment variable is not set');
    }

    const endDate = new Date(upcomingMonday);
    endDate.setUTCDate(upcomingMonday.getUTCDate() + 7);
    const competitionId = uuid();

    await CompetitionQueries.createPublicCompetition({
        startDate: upcomingMonday,
        endDate,
        displayName: 'Weekly challenge - see how you stack up',
        adminUserId: UserHelpers.convertUserIdToBuffer(adminUserId),
        accessToken: cryptoHelpers.getRandomToken(),
        ianaTimezone: 'UTC',
        competitionId
    });

    return `Created weekly competition starting ${upcomingMonday.toISOString()}`;
}


export default router;