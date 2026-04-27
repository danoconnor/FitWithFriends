'use strict';
import * as express from 'express';
import * as ActivityDataQueries from '../sql/activityData.queries';
import * as CompetitionQueries from '../sql/competitions.queries';
import * as UserQueries from '../sql/users.queries';
import { handleError } from '../utilities/errorHelpers';
import * as UserHelpers from '../utilities/userHelpers';
import { v4 as uuid } from 'uuid';

const router = express.Router();

// Guard: all endpoints in this router are disabled unless FWF_ENABLE_TEST_HELPERS=true.
router.use(function (_req, res, next) {
    if (process.env.FWF_ENABLE_TEST_HELPERS !== 'true') {
        res.sendStatus(401);
        return;
    }
    next();
});

router.post('/setUserProStatus', function (req, res) {
    const userId: string = req.body['userId'];
    const isPro: boolean = req.body['isPro'];

    if (!userId || isPro === undefined || isPro === null) {
        handleError(null, 400, 'Missing required parameter', res);
        return;
    }

    UserQueries.updateUserProStatus({
        userId: UserHelpers.convertUserIdToBuffer(userId),
        isPro,
        maxActiveCompetitions: isPro ? 10 : 1
    })
        .then(() => {
            res.sendStatus(200);
        })
        .catch(error => {
            handleError(error, 500, 'Error updating user pro status', res);
        });
});

// Creates fake users, adds them to a competition, and inserts activity summaries
// for every day from the competition's start date through today (inclusive).
interface DayValues {
    caloriesBurned: number;
    caloriesGoal: number;
    exerciseTime: number;
    exerciseTimeGoal: number;
    standTime: number;
    standTimeGoal: number;
    stepCount?: number;
    distanceWalkingRunningMeters?: number;
    flightsClimbed?: number;
}

router.post('/seedCompetitionUsers', async function (req, res) {
    const competitionId: string = req.body['competitionId'];
    const users: Array<DayValues & {
        firstName: string;
        lastName: string;
        // Optional per-day overrides. If provided, values cycle through the array
        // for each competition day instead of repeating the flat values above.
        dailyData?: DayValues[];
    }> = req.body['users'];

    if (!competitionId || !users || !Array.isArray(users) || users.length === 0) {
        handleError(null, 400, 'Missing required parameter', res);
        return;
    }

    try {
        const competitions = await CompetitionQueries.getCompetition({ competitionId });
        if (competitions.length === 0) {
            handleError(null, 404, 'Competition not found', res);
            return;
        }

        const startDate = new Date(competitions[0].start_date);
        startDate.setHours(0, 0, 0, 0);

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const dates: Date[] = [];
        const cursor = new Date(startDate);
        while (cursor <= today) {
            dates.push(new Date(cursor));
            cursor.setDate(cursor.getDate() + 1);
        }

        const createdUserIds: string[] = [];

        for (const user of users) {
            const userId = uuid().replace(/-/g, '');
            const userIdBuffer = UserHelpers.convertUserIdToBuffer(userId);

            await UserQueries.createUser({
                userId: userIdBuffer,
                firstName: user.firstName,
                lastName: user.lastName,
                maxActiveCompetitions: 1,
                isPro: false,
                createdDate: new Date()
            });

            await CompetitionQueries.addUserToCompetition({ userId: userIdBuffer, competitionId });

            if (dates.length > 0) {
                await ActivityDataQueries.insertActivitySummaries({
                    summaries: dates.map((date, index) => {
                        const day: DayValues = user.dailyData && user.dailyData.length > 0
                            ? user.dailyData[index % user.dailyData.length]
                            : user;
                        return {
                            userId: userIdBuffer,
                            date,
                            caloriesBurned: day.caloriesBurned,
                            caloriesGoal: day.caloriesGoal,
                            exerciseTime: day.exerciseTime,
                            exerciseTimeGoal: day.exerciseTimeGoal,
                            standTime: day.standTime,
                            standTimeGoal: day.standTimeGoal,
                            stepCount: day.stepCount ?? 0,
                            distanceWalkingRunningMeters: day.distanceWalkingRunningMeters ?? 0,
                            flightsClimbed: day.flightsClimbed ?? 0
                        };
                    })
                });
            }

            createdUserIds.push(userId);
        }

        res.status(200).json({ userIds: createdUserIds });
    } catch (error) {
        handleError(error, 500, 'Error seeding competition users', res);
    }
});

// POST /testHelpers/setCompetitionArchived
// Body: { competitionId: string, userFinalPoints: [{ userId: string, points: number }] }
router.post('/setCompetitionArchived', async function (req, res) {
    const competitionId: string = req.body['competitionId'];
    const userFinalPoints: Array<{ userId: string; points: number }> = req.body['userFinalPoints'] ?? [];

    if (!competitionId) {
        handleError(null, 400, 'Missing required parameter', res);
        return;
    }

    try {
        for (const entry of userFinalPoints) {
            await CompetitionQueries.updateCompetitionFinalPoints({
                userId: UserHelpers.convertUserIdToBuffer(entry.userId),
                competitionId,
                finalPoints: entry.points
            });
        }
        await CompetitionQueries.updateCompetitionState({ competitionId, newState: 3 });
        res.sendStatus(200);
    } catch (error) {
        handleError(error, 500, 'Error archiving competition', res);
    }
});

export default router;
