'use strict';
import * as express from 'express';
import * as CompetitionQueries from '../sql/competitions.queries';
import * as OAuthQueries from '../sql/oauth.queries';
import { sendPushNotifications } from '../utilities/apnsHelper';
import { CompetitionState } from '../utilities/enums/CompetitionState';
import { handleError } from '../utilities/errorHelpers';
import * as UserHelpers from '../utilities/userHelpers';
import { getCompetitionStandings } from '../utilities/competitionStandingsHelper';

const router = express.Router();

router.post('/performDailyTasks', async function (req, res) {
    var errors: [taskName: string, error: Error][] = [];

    const deleteExpiredTokensPromise = deleteExpiredRefreshTokens();

    // Do not parallelize the competition tasks
    // because we do not want to move a competition to processing to archiving in the same run
    // This should not happen but could happen if the cron job has not been run recently
    try {
        await archiveCompetitions();
    } catch (err) {
        errors.push(['archiveCompetitions', err]);
    }

    try {
        await processesRecentlyEndedCompetitions();
    } catch (err) {
        errors.push(['processRecentlyEndedCompetitions', err]);
    }

    try {
        await deleteExpiredTokensPromise;
    } catch (err) {
        errors.push(['deleteExpiredRefreshTokens', err]);
    }

    if (errors.length > 0) {
        const errorDetails = errors.map(e => `${e[0]}: ${e[1].message}`).join(', ');
        console.error('Error performing daily tasks:', errorDetails);

        return handleError(
            errors[0][1], // Use the first error for the response
            500,
            errorDetails,
            res
        );
    } else {
        console.log('Daily tasks completed');
        res.sendStatus(200);
    }
});

// Get recently ended competitions
// Move them to the processing state
// Send push notifications to users
async function processesRecentlyEndedCompetitions() {
    const now = new Date();
    const competitionsToMoveToProcessing = await CompetitionQueries.getCompetitionsInState({ 
        state: CompetitionState.NotStartedOrActive, 
        finishedBeforeDate: now
     });

     // Update competitions to processing state
     await Promise.all(competitionsToMoveToProcessing.map(competition => {
         return CompetitionQueries.updateCompetitionState({ competitionId: competition.competition_id, newState: CompetitionState.ProcessingResults });
     }));

     if (competitionsToMoveToProcessing.length === 0) {
        console.log('No competitions to process');
        return;
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
}

// Get competitions that have been in the processing state for more than 24 hours
// Move them to the archived state and archive results
// Send final results push notifications
async function archiveCompetitions() {
    const now = new Date();
    const olderThan24Hrs = new Date(now.getTime() - (24 * 60 * 60 * 1000));
     const competitionsToArchive = await CompetitionQueries.getCompetitionsInState({ 
        state: CompetitionState.ProcessingResults,
        finishedBeforeDate: olderThan24Hrs
     });

    if (competitionsToArchive.length === 0) {
        console.log('No competitions to archive');
        return;
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
}

async function deleteExpiredRefreshTokens() {
    const now = new Date();
    await OAuthQueries.deleteExpiredRefreshTokens({ currentDate: now });
}

export default router;