'use strict';
import * as express from 'express';
import * as CompetitionQueries from '../sql/competitions.queries';
import { Json } from '../sql/competitions.queries';
import { getWeekTemplates } from '../utilities/weeklyCompetitionSchedule';
import * as UserQueries from '../sql/users.queries';
import * as OAuthQueries from '../sql/oauth.queries';
import * as ActivityDataQueries from '../sql/activityData.queries';
import { sendPushNotifications } from '../utilities/apnsHelper';
import { CompetitionState } from '../utilities/enums/CompetitionState';
import { handleError } from '../utilities/errorHelpers';
import * as UserHelpers from '../utilities/userHelpers';
import { getCompetitionStandings, validateScoringRulesInput } from '../utilities/competitionStandingsHelper';
import { isWithinNotificationWindow, isValidTimeZone } from '../utilities/timezoneHelpers';
import * as cryptoHelpers from '../utilities/cryptoHelpers';

// Competitions stay eligible for end-of-competition notifications for a few days
// after they finish, giving every member's local morning window time to arrive
// (even the westmost timezones, the morning after archival) plus slack for retries.
const NOTIFICATION_WINDOW_DAYS = 3;

const router = express.Router();

const MAX_BOT_USERS = 100;

const BOT_FIRST_NAMES = [
    'Alex', 'Jordan', 'Casey', 'Morgan', 'Riley', 'Taylor', 'Jamie', 'Drew', 'Avery', 'Quinn',
    'Sam', 'Blake', 'Cameron', 'Jesse', 'Kyle', 'Dana', 'Robin', 'Pat', 'Terry', 'Lee',
    'Chris', 'Kim', 'Leslie', 'Frankie', 'Reese', 'Parker', 'Skyler', 'Finley', 'Logan', 'Hayden',
    'Spencer', 'Kendall', 'Sage', 'Rowan', 'Emery', 'Scout', 'River', 'Remy', 'Elliot', 'Peyton',
    'Dylan', 'Shawn', 'Devon', 'Corey', 'Harley', 'Bailey', 'Charlie', 'Jody', 'Angel', 'Bobbie',
];
const BOT_LAST_NAMES = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Miller', 'Davis', 'Wilson', 'Moore', 'Anderson',
    'Taylor', 'Thomas', 'Jackson', 'White', 'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson',
    'Clark', 'Rodriguez', 'Lewis', 'Lee', 'Walker', 'Hall', 'Allen', 'Young', 'Hernandez', 'King',
    'Wright', 'Lopez', 'Hill', 'Scott', 'Green', 'Adams', 'Baker', 'Gonzalez', 'Nelson', 'Carter',
    'Mitchell', 'Perez', 'Roberts', 'Turner', 'Phillips', 'Campbell', 'Parker', 'Evans', 'Edwards', 'Collins',
];

router.post('/createPublicCompetition', function (req, res) {
    const startDate = new Date(req.body['startDate']);
    const endDate = new Date(req.body['endDate']);
    const displayName: string = req.body['displayName'];
    const timezone: string = req.body['ianaTimezone'];
    const adminUserId: string = req.body['adminUserId'];
    const rawScoringRules: unknown = req.body['scoringRules'];

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

    if (rawScoringRules !== undefined && rawScoringRules !== null) {
        const validationError = validateScoringRulesInput(rawScoringRules);
        if (validationError) {
            handleError(null, 400, `Invalid scoringRules: ${validationError}`, res, true);
            return;
        }
    }

    const startDateUTC = new Date(startDate.toUTCString());
    const endDateUTC = new Date(endDate.toUTCString());
    const accessToken = cryptoHelpers.getRandomToken();
    const competitionId = crypto.randomUUID();

    const scoringRulesForDb: Json | null = (rawScoringRules !== undefined && rawScoringRules !== null) ? (rawScoringRules as Json) : null;

    CompetitionQueries.createPublicCompetition({
        startDate: startDateUTC,
        endDate: endDateUTC,
        displayName,
        adminUserId: UserHelpers.convertUserIdToBuffer(adminUserId),
        accessToken,
        ianaTimezone: timezone,
        competitionId,
        scoringRules: scoringRulesForDb
    })
        .then(async (_result) => {
            const botUsers = await UserQueries.getBotUsers();
            await Promise.all(botUsers.map(bot =>
                CompetitionQueries.addUserToCompetition({
                    userId: UserHelpers.convertUserIdToBuffer(bot.userId),
                    competitionId
                })
            ));
            res.json({ 'competition_id': competitionId });
        })
        .catch(error => {
            handleError(error, 500, 'Error creating public competition', res);
        });
});

router.post('/createBotUsers', async function (req, res) {
    const count: number = parseInt(req.body['count']);
    if (isNaN(count) || count <= 0) {
        handleError(null, 400, 'count must be a positive integer', res);
        return;
    }

    const countResult = await UserQueries.getBotUserCount();
    const currentCount = countResult[0]?.count ?? 0;

    if (currentCount >= MAX_BOT_USERS) {
        handleError(null, 400, `Bot user limit of ${MAX_BOT_USERS} already reached`, res);
        return;
    }

    const canCreate = Math.min(count, MAX_BOT_USERS - currentCount);
    const now = new Date();

    const botUserIds: string[] = [];
    await Promise.all(
        Array.from({ length: canCreate }, async () => {
            const userId = crypto.randomUUID().replace(/-/g, '');
            const firstName = BOT_FIRST_NAMES[Math.floor(Math.random() * BOT_FIRST_NAMES.length)];
            const lastName = BOT_LAST_NAMES[Math.floor(Math.random() * BOT_LAST_NAMES.length)];
            await UserQueries.createBotUser({
                userId: UserHelpers.convertUserIdToBuffer(userId),
                firstName,
                lastName,
                maxActiveCompetitions: 1,
                isPro: false,
                createdDate: now
            });
            botUserIds.push(userId);
        })
    );

    // Enroll new bots in all active public competitions
    const activePublicCompetitions = await CompetitionQueries.getPublicCompetitions({
        activeState: CompetitionState.NotStartedOrActive
    });
    await Promise.all(
        botUserIds.flatMap(userId =>
            activePublicCompetitions.map(competition =>
                CompetitionQueries.addUserToCompetition({
                    userId: UserHelpers.convertUserIdToBuffer(userId),
                    competitionId: competition.competition_id
                })
            )
        )
    );

    res.json({
        created: canCreate,
        userIds: botUserIds,
        total: currentCount + canCreate
    });
});

router.post('/performDailyTasks', async function (req, res) {
    let taskResults: { name: string; result: string; warning?: string }[] = [];
    let errors: [taskName: string, error: Error][] = [];

    // Optional currentDate override — allows callers (e.g. tests) to specify what
    // "now" means for this run without restarting the server.
    const now = req.body['currentDate'] ? new Date(req.body['currentDate']) : new Date();

    // Run tasks sequentially to avoid unhandled rejections from pre-started promises failing
    // while awaiting other tasks. Competition tasks are serialized to prevent a competition
    // from advancing two states in one run.
    try {
        taskResults.push({ name: 'archiveCompetitions', ...await archiveCompetitions(now) });
    } catch (err) {
        errors.push(['archiveCompetitions', err]);
    }

    try {
        taskResults.push({ name: 'processRecentlyEndedCompetitions', result: await processesRecentlyEndedCompetitions(now) });
    } catch (err) {
        errors.push(['processRecentlyEndedCompetitions', err]);
    }

    // Runs after the state transitions above so a competition that advanced this
    // run is immediately eligible to notify members whose local morning has arrived.
    try {
        taskResults.push({ name: 'sendCompetitionNotifications', ...await sendDueCompetitionNotifications(now) });
    } catch (err) {
        errors.push(['sendCompetitionNotifications', err]);
    }

    try {
        taskResults.push({ name: 'deleteExpiredRefreshTokens', result: await deleteExpiredRefreshTokens(now) });
    } catch (err) {
        errors.push(['deleteExpiredRefreshTokens', err]);
    }

    try {
        taskResults.push({ name: 'createWeeklyPublicCompetition', result: await createWeeklyPublicCompetition(now) });
    } catch (err) {
        errors.push(['createWeeklyPublicCompetition', err]);
    }

    try {
        taskResults.push({ name: 'seedBotActivityData', result: await seedBotActivityData(now) });
    } catch (err) {
        errors.push(['seedBotActivityData', err]);
    }

    const summary = {
        tasks: taskResults,
        warnings: taskResults.filter(t => t.warning).map(t => ({ name: t.name, warning: t.warning! })),
        errors: errors.map(([name, error]) => ({
            name,
            error: error.message,
            errorType: error.constructor?.name ?? 'Error'
        }))
    };

    if (errors.length > 0) {
        console.error('Error performing daily tasks:', summary);
        return res.status(500).json(summary);
    } else {
        console.log('Daily tasks completed:', summary);
        return res.status(200).json(summary);
    }
});

// Get recently ended competitions and move them to the processing state.
// Push notifications are sent separately, per-user at each member's local 8am,
// by sendDueCompetitionNotifications.
async function processesRecentlyEndedCompetitions(now: Date): Promise<string> {
    const competitionsToMoveToProcessing = await CompetitionQueries.getCompetitionsInState({
        state: CompetitionState.NotStartedOrActive,
        finishedBeforeDate: now
     });

     if (competitionsToMoveToProcessing.length === 0) {
        return 'No competitions to process';
     }

     // Update competitions to processing state
     await Promise.all(competitionsToMoveToProcessing.map(competition => {
         return CompetitionQueries.updateCompetitionState({ competitionId: competition.competition_id, newState: CompetitionState.ProcessingResults });
     }));

     return `Moved ${competitionsToMoveToProcessing.length} competition(s) to processing state`;
}

// Get competitions that have been in the processing state for more than 24 hours.
// Freeze each member's final points and move the competition to the archived state.
// The final-results push notifications are sent separately, per-user at each
// member's local 8am, by sendDueCompetitionNotifications (which reads the frozen
// final_points to compute placement).
async function archiveCompetitions(now: Date): Promise<{ result: string; warning?: string }> {
    const olderThan24Hrs = new Date(now.getTime() - (24 * 60 * 60 * 1000));
     const competitionsToArchive = await CompetitionQueries.getCompetitionsInState({
        state: CompetitionState.ProcessingResults,
        finishedBeforeDate: olderThan24Hrs
     });

    if (competitionsToArchive.length === 0) {
        return { result: 'No competitions to archive' };
    }

    const pointsErrors: string[] = [];

    // Calculate and freeze the final results for each competition
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

            // Freeze each user's final points. The per-user results notification
            // (sent later, at each member's local 8am) ranks members from these
            // frozen values, so they must be written before the competition archives.
            await Promise.all(Object.values(competitionResults).map(userPoints =>
                CompetitionQueries.updateCompetitionFinalPoints({
                    userId: UserHelpers.convertUserIdToBuffer(userPoints.userId),
                    competitionId: competition.competition_id,
                    finalPoints: userPoints.activityPoints
                })
            ));
        } catch (err) {
            // Log the error but continue processing other competitions
            console.error(`Error calculating final results for competition ${competition.competition_id}:`, err);
            pointsErrors.push(`competition ${competition.competition_id}: ${(err as Error).message}`);
        }
    }

    // Update competitions to archived state
    await Promise.all(competitionsToArchive.map(competition => {
        return CompetitionQueries.updateCompetitionState({ competitionId: competition.competition_id, newState: CompetitionState.Archived });
    }));

    const result = `Archived ${competitionsToArchive.length} competition(s)`;
    return pointsErrors.length > 0
        ? { result, warning: `final-points errors: ${pointsErrors.join(', ')}` }
        : { result };
}

// Converts a 1-based placement into the wording used in the results notification.
function ordinalPlace(place: number): string {
    switch (place) {
        case 1: return 'first';
        case 2: return 'second';
        case 3: return 'third';
        default: return `${place}th`;
    }
}

// Sends the two end-of-competition push notifications per-user, at each member's
// local ~8am (their preferred_timezone, falling back to the competition timezone):
//   - "processing" while the competition is in the ProcessingResults state
//   - "final results" once it has archived (placement read from frozen final_points)
// Delivery is tracked per (user, competition) via the sent_* flags so each member
// is notified once at their own local morning. A member is marked only when a push
// is actually delivered, so throttled/failed sends retry on the next run. Bots are
// excluded by the query. Seeing the results in-app also satisfies the flags (the
// client marks them), so this is a fallback for members who haven't opened the app.
async function sendDueCompetitionNotifications(now: Date): Promise<{ result: string; warning?: string }> {
    const finishedAfter = new Date(now.getTime() - NOTIFICATION_WINDOW_DAYS * 24 * 60 * 60 * 1000);
    const pending = await CompetitionQueries.getPendingCompetitionNotifications({
        finishedAfter,
        processingState: CompetitionState.ProcessingResults,
        archivedState: CompetitionState.Archived
    });

    if (pending.length === 0) {
        return { result: 'No competition notifications to send' };
    }

    // Group the pending member rows by competition
    const byCompetition = new Map<string, typeof pending>();
    for (const row of pending) {
        const list = byCompetition.get(row.competition_id) ?? [];
        list.push(row);
        byCompetition.set(row.competition_id, list);
    }

    let totalSent = 0;
    const warnings: string[] = [];

    for (const [competitionId, rows] of byCompetition) {
        const state = rows[0].state;
        const displayName = rows[0].display_name;
        const competitionTimezone = rows[0].iana_timezone;

        // Build the placement ranking once (archived only) from frozen final_points,
        // across ALL members including bots so positions match the leaderboard.
        let placeByUser: Map<string, number> | null = null;
        if (state === CompetitionState.Archived) {
            const allMembers = await CompetitionQueries.getUsersForCompetition({ competitionId });
            const ranked = allMembers
                .map(m => ({ userId: UserHelpers.convertBufferToUserId(m.user_id), points: m.final_points ?? 0 }))
                .sort((a, b) => b.points - a.points);
            placeByUser = new Map(ranked.map((m, i) => [m.userId, i + 1]));
        }

        // Select the members whose local morning window has arrived and who still
        // need this competition's notification.
        const notifications: { userId: string; title: string; body: string }[] = [];
        const eligibleUserIds: string[] = [];
        for (const row of rows) {
            const alreadySent = state === CompetitionState.Archived
                ? row.sent_complete_notification
                : row.sent_processing_notification;
            if (alreadySent) continue;

            // Use the member's reported timezone, falling back to the competition's
            // when it's missing or not a resolvable IANA zone.
            const tz = (row.preferred_timezone && isValidTimeZone(row.preferred_timezone))
                ? row.preferred_timezone
                : competitionTimezone;
            if (!isWithinNotificationWindow(now, tz)) continue;

            eligibleUserIds.push(row.user_id);
            if (state === CompetitionState.Archived) {
                const place = placeByUser!.get(row.user_id) ?? 0;
                const points = row.final_points ?? 0;
                notifications.push({
                    userId: row.user_id,
                    title: `The competition "${displayName}" has ended!`,
                    body: `You came in ${ordinalPlace(place)} place with ${points} points!`,
                });
            } else {
                notifications.push({
                    userId: row.user_id,
                    title: `The competition "${displayName}" has ended!`,
                    body: 'The final results are being processed and will be posted tomorrow',
                });
            }
        }

        if (notifications.length === 0) continue;

        const sendResult = await sendPushNotifications(notifications);
        totalSent += sendResult.sent;

        // Mark only the members we actually delivered to. Undelivered members keep
        // their flag false and are retried on the next run (still in their window).
        const markSent = state === CompetitionState.Archived
            ? CompetitionQueries.markCompleteNotificationSent
            : CompetitionQueries.markProcessingNotificationSent;
        await Promise.all(sendResult.succeededUserIds.map(userId =>
            markSent({ userId: UserHelpers.convertUserIdToBuffer(userId), competitionId })
        ));

        const undelivered = eligibleUserIds.length - sendResult.succeededUserIds.length;
        if (undelivered > 0) {
            const kind = state === CompetitionState.Archived ? 'results' : 'processing';
            warnings.push(`competition ${competitionId}: ${undelivered} ${kind} notification(s) not delivered (will retry)`);
        }
    }

    const result = `Sent ${totalSent} competition notification(s)`;
    return warnings.length > 0 ? { result, warning: warnings.join('; ') } : { result };
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
    // Use UTC date strings so pg does not apply a local-timezone offset when writing
    // to the DATE column (which has no time component).
    const startDateStr = upcomingMonday.toISOString().slice(0, 10);
    const endDateStr = new Date(upcomingMonday.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);

    // Check if a competition for the upcoming week already exists.
    // Compare date strings directly to avoid local-vs-UTC midnight mismatches.
    const activePublicCompetitions = await CompetitionQueries.getPublicCompetitions({
        activeState: CompetitionState.NotStartedOrActive
    });
    const alreadyScheduled = activePublicCompetitions.some(c => {
        const storedDate = c.start_date instanceof Date
            ? c.start_date.toISOString().slice(0, 10)
            : String(c.start_date).slice(0, 10);
        return storedDate >= startDateStr;
    });
    if (alreadyScheduled) {
        return 'Skipped: competition for upcoming week already exists';
    }

    const adminUserId = process.env.FWF_SYSTEM_ADMIN_USER_ID;
    if (!adminUserId) {
        throw new Error('FWF_SYSTEM_ADMIN_USER_ID environment variable is not set');
    }

    const [templateA, templateB] = getWeekTemplates(upcomingMonday);
    const botUsers = await UserQueries.getBotUsers();

    for (const template of [templateA, templateB]) {
        const competitionId = crypto.randomUUID();
        await CompetitionQueries.createPublicCompetition({
            startDate: startDateStr,
            endDate: endDateStr,
            displayName: template.displayName,
            adminUserId: UserHelpers.convertUserIdToBuffer(adminUserId),
            accessToken: cryptoHelpers.getRandomToken(),
            ianaTimezone: 'UTC',
            competitionId,
            scoringRules: template.scoringRules
        });
        await Promise.all(botUsers.map(bot =>
            CompetitionQueries.addUserToCompetition({
                userId: UserHelpers.convertUserIdToBuffer(bot.userId),
                competitionId
            })
        ));
    }

    return `Created 2 weekly competitions starting ${upcomingMonday.toISOString()}`;
}


async function seedBotActivityData(now: Date): Promise<string> {
    const botUsers = await UserQueries.getBotUsers();
    if (botUsers.length === 0) return 'No bot users found';

    // Get current Eastern time details
    const easternHour = parseInt(
        new Intl.DateTimeFormat('en-US', { hour: 'numeric', hour12: false, timeZone: 'America/New_York' }).format(now)
    );
    const easternDateStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/New_York' }).format(now); // "YYYY-MM-DD"

    // Fetch today's existing activity for all bots (single query)
    const botUserBuffers = botUsers.map(bot => UserHelpers.convertUserIdToBuffer(bot.userId));
    const existingActivity = await ActivityDataQueries.getActivitySummariesForUsers({
        userIds: botUserBuffers,
        startDate: easternDateStr,
        endDate: easternDateStr,
    });
    const existingByUser = new Map(existingActivity.map(a => [a.userId, a]));

    // Build incremented summaries
    const summaries = botUsers.map(bot => {
        const existing = existingByUser.get(bot.userId);
        const currentCalories = existing?.calories_burned ?? 0;
        const currentExercise = existing?.exercise_time ?? 0;
        const currentStand = existing?.stand_time ?? 0;
        const currentSteps = existing?.step_count ?? 0;
        const currentDistance = existing?.distance_walking_running_meters ?? 0;
        const currentFlights = existing?.flights_climbed ?? 0;

        return {
            userId: UserHelpers.convertUserIdToBuffer(bot.userId),
            date: easternDateStr,
            caloriesBurned: currentCalories + Math.floor(Math.random() * 61) + 5,  // +5–65 per run
            caloriesGoal: 500,
            exerciseTime: currentExercise + Math.floor(Math.random() * 8),           // +0–7 min per run
            exerciseTimeGoal: 30,
            standTime: Math.min(currentStand + (Math.random() < 0.6 ? 1 : 0), easternHour), // capped at Eastern hour
            standTimeGoal: 12,
            stepCount: currentSteps + Math.floor(Math.random() * 600) + 100,         // +100–700 per run
            distanceWalkingRunningMeters: currentDistance + Math.floor(Math.random() * 500) + 50, // +50–550 m per run
            flightsClimbed: currentFlights + (Math.random() < 0.3 ? 1 : 0),          // occasional flight
        };
    });

    await ActivityDataQueries.insertActivitySummaries({ summaries });

    // Seed 0–2 workouts per bot for today.
    // HKWorkoutActivityType raw values: 37 = running, 46 = swimming, 50 = traditionalStrengthTraining
    const BOT_WORKOUT_TYPES = [37, 46, 50];
    // Fixed UTC time slots make re-seeding idempotent via ON CONFLICT DO NOTHING
    const BOT_WORKOUT_SLOTS_UTC = ['T08:00:00.000Z', 'T14:00:00.000Z'];

    const workoutsToInsert: {
        userId: Buffer;
        startDate: Date;
        caloriesBurned: number;
        workoutType: number;
        duration: number;
        distance: number | null;
        unit: number | null;
    }[] = [];

    for (const bot of botUsers) {
        const numWorkouts = Math.floor(Math.random() * 3); // 0, 1, or 2
        for (let i = 0; i < numWorkouts; i++) {
            const workoutType = BOT_WORKOUT_TYPES[Math.floor(Math.random() * BOT_WORKOUT_TYPES.length)];
            const durationSecs = Math.floor(Math.random() * 9001) + 1800; // 30–180 min
            const caloriesBurned = Math.floor(Math.random() * 1001) + 200; // 200–1200 kcal

            let distance: number | null = null;
            let unit: number | null = null;
            if (workoutType === 37) { // running
                distance = Math.floor(Math.random() * 8000) + 2000; // 2–10 km in meters
                unit = 2; // meter
            } else if (workoutType === 46) { // swimming
                distance = Math.floor(Math.random() * 1500) + 500; // 500–2000 m
                unit = 2; // meter
            }

            workoutsToInsert.push({
                userId: UserHelpers.convertUserIdToBuffer(bot.userId),
                startDate: new Date(`${easternDateStr}${BOT_WORKOUT_SLOTS_UTC[i]}`),
                caloriesBurned,
                workoutType,
                duration: durationSecs,
                distance,
                unit,
            });
        }
    }

    if (workoutsToInsert.length > 0) {
        await ActivityDataQueries.insertWorkouts({ workouts: workoutsToInsert });
    }

    return `Seeded activity data for ${botUsers.length} bot users`;
}

export default router;