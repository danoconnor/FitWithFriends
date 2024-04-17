'use strict';
import { handleError } from "../utilities/errorHelpers";
import * as ActivitySummaryQueries from "../sql/activitySummaries.queries";
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
        user_id: Buffer; 
        date: Date; 
        calories_burned: number; 
        calories_goal: number; 
        exercise_time: number; 
        exercise_time_goal: number;
        stand_time: number; 
        stand_time_goal: number; }[] = [];

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
            user_id: userIdBuffer,
            date,
            calories_burned: caloriesBurned,
            calories_goal: caloriesGoal,
            exercise_time: exerciseTime,
            exercise_time_goal: exerciseTimeGoal,
            stand_time: standTime,
            stand_time_goal: standTimeGoal
        });
    }

    ActivitySummaryQueries.insertActivitySummaries({ summaries: summariesToInsert })
        .then(_result => {
            res.sendStatus(200);
        })
        .catch(error => {
            handleError(error, 500, 'Unexpected error inserting data into database', res);
        });
});

export default router;