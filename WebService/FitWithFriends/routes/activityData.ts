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

    ActivityDataQueries.insertActivitySummaries({ summaries: summariesToInsert })
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
        const duration: number = Math.round(workout['duration']);
        const distance: number | null = workout['distance'] === undefined ? null : Math.round(workout['distance']);
        const unit: number | null = workout['unit'] === undefined ? null : workout['unit'];

        if (!startDateStr || workoutType == undefined || Number.isNaN(workoutType) || Number.isNaN(duration) || Number.isNaN(caloriesBurned)) {
            handleError(null, 400, 'Missing required parameter', res);
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
            duration,
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