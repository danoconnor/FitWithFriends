'use strict';
import { handleError } from "../utilities/errorHelpers";
import * as ActivityDataQueries from "../sql/activityData.queries";
import { DatabaseConnectionPool } from "../utilities/database";
import * as express from "express";
import { convertUserIdToBuffer } from "../utilities/userHelpers";
const router = express.Router();

// Expect a POST request with a JSON body with a values key and an array of activity summaries as the value
router.post('/dailySummary', function (req, res) {
    const summaries = req.body['values'];
    if (!summaries || !Array.isArray(summaries) || summaries.length === 0) {
        handleError(null, 400, 'Missing required parameter', res);
        return;
    }

    const userId: string = res.locals.oauth.token.user.id;
    const userIdBuffer = convertUserIdToBuffer(userId);

    var summariesToInsert: { 
        userId: Buffer; 
        date: Date; 
        caloriesBurned: number; 
        caloriesGoal: number; 
        exerciseTime: number; 
        exerciseTimeGoal: number;
        standTime: number; 
        standTimeGoal: number; }[] = [];

    for (const summary of summaries) {
        const dateStr: string = summary['date'];
        const caloriesBurned: number = Math.round(summary['activeCaloriesBurned']);
        const caloriesGoal: number = Math.round(summary['activeCaloriesGoal']);
        const exerciseTime: number = Math.round(summary['exerciseTime']);
        const exerciseTimeGoal: number = Math.round(summary['exerciseTimeGoal']);
        const standTime: number = Math.round(summary['standTime']);
        const standTimeGoal: number = Math.round(summary['standTimeGoal']);

        if (!dateStr || Number.isNaN(caloriesBurned) || Number.isNaN(caloriesGoal) || Number.isNaN(exerciseTime) || Number.isNaN(exerciseTimeGoal) || Number.isNaN(standTime) || Number.isNaN(standTimeGoal)) {
            handleError(null, 400, 'Missing required parameter', res);
            return;
        }
    
        const date = new Date(dateStr);
        if (isNaN(date.getTime())) {
            handleError(null, 400, 'Could not parse date', res);
            return;
        }

        summariesToInsert.push({
            userId: userIdBuffer,
            date,
            caloriesBurned,
            caloriesGoal,
            exerciseTime,
            exerciseTimeGoal,
            standTime,
            standTimeGoal
        });
    }

    // Deduplicate by date: if the client sends multiple entries for the same date,
    // merge them by taking the max values (consistent with the ON CONFLICT DO UPDATE logic).
    // PostgreSQL cannot update the same target row twice in one statement.
    const summaryByDate = new Map<string, typeof summariesToInsert[0]>();
    for (const summary of summariesToInsert) {
        const key = summary.date.toISOString();
        const existing = summaryByDate.get(key);
        if (existing) {
            existing.caloriesBurned = Math.max(existing.caloriesBurned, summary.caloriesBurned);
            existing.caloriesGoal = Math.max(existing.caloriesGoal, summary.caloriesGoal);
            existing.exerciseTime = Math.max(existing.exerciseTime, summary.exerciseTime);
            existing.exerciseTimeGoal = Math.max(existing.exerciseTimeGoal, summary.exerciseTimeGoal);
            existing.standTime = Math.max(existing.standTime, summary.standTime);
            existing.standTimeGoal = Math.max(existing.standTimeGoal, summary.standTimeGoal);
        } else {
            summaryByDate.set(key, summary);
        }
    }

    ActivityDataQueries.insertActivitySummaries({ summaries: Array.from(summaryByDate.values()) })
        .then(_result => {
            res.sendStatus(200);
        })
        .catch(error => {
            handleError(error, 500, 'Unexpected error inserting activity summaries into database', res);
        });
});

// Expect a POST request with a JSON body with a values key and an array of workouts as the value
router.post('/workouts', function (req, res) {
    const workouts = req.body['values'];
    if (!workouts || !Array.isArray(workouts) || workouts.length === 0) {
        handleError(null, 400, 'Missing required parameter', res);
        return;
    }

    const userId: string = res.locals.oauth.token.user.id;
    const userIdBuffer = convertUserIdToBuffer(userId);

    var workoutsToInsert: {
        userId: Buffer,
        startDate: Date,
        caloriesBurned: number,
        workoutType: number,
        duration: number,
        distance: number | null,
        unit: number | null
      }[] = [];

    for (const workout of workouts) {
        const startDateStr: string = workout['startDate'];
        const caloriesBurned: number = Math.round(workout['caloriesBurned']);
        // TODO: We should translate this to a platform agnostic value
        const workoutType: number = workout['appleActivityTypeRawValue'];
        // Duration is in seconds
        const durationSecs: number = Math.round(workout['duration']);
        const distance: number | null = workout['distance'] === undefined ? null : Math.round(workout['distance']);
        const unit: number | null = workout['unit'] === undefined ? null : workout['unit'];

        if (!startDateStr || workoutType == undefined || Number.isNaN(workoutType) || Number.isNaN(durationSecs) || Number.isNaN(caloriesBurned)) {
            handleError(null, 400, 'Missing required parameter', res);
            return;
        }

        if (unit !== null && Number.isNaN(unit)) {
            handleError(null, 400, 'Invalid unit', res);
            return;
        }

        if ((distance === null) !== (unit === null || unit === 0)) {
            handleError(null, 400, 'distance and unit must both be provided or both be omitted', res);
            return;
        }

        const startDate = new Date(startDateStr);
        if (isNaN(startDate.getTime())) {
            handleError(null, 400, 'Could not parse date', res);
            return;
        }

        workoutsToInsert.push({
            userId: userIdBuffer,
            startDate,
            caloriesBurned,
            workoutType,
            duration: durationSecs,
            distance,
            unit
        });
    }

    ActivityDataQueries.insertWorkouts({ workouts: workoutsToInsert })
        .then(_result => {
            res.sendStatus(200);
        })
        .catch(error => {
            handleError(error, 500, 'Unexpected error inserting workouts into database', res);
        });
});

export default router;