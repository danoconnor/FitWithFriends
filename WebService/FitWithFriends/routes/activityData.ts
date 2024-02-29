'use strict';
import { handleError } from "../utilities/errorHelpers";
import * as ActivitySummaryQueries from "../sql/activitySummaries.queries";
import { DatabaseConnectionPool } from "../utilities/database";
import * as express from "express";
import { convertUserIdToBuffer } from "../utilities/userHelpers";
const router = express.Router();

router.post('/dailySummary', function (req, res) {
    const dateStr: string = req.body['date'];
    const caloriesBurned: number = Math.round(req.body['activeCaloriesBurned']);
    const caloriesGoal: number = Math.round(req.body['activeCaloriesGoal']);
    const exerciseTime: number = Math.round(req.body['exerciseTime']);
    const exerciseTimeGoal: number = Math.round(req.body['exerciseTimeGoal']);
    const standTime: number = Math.round(req.body['standTime']);
    const standTimeGoal: number = Math.round(req.body['standTimeGoal']);

    const userId: string = res.locals.oauth.token.user.id;

    if (!dateStr || Number.isNaN(caloriesBurned) || Number.isNaN(caloriesGoal) || Number.isNaN(exerciseTime) || Number.isNaN(exerciseTimeGoal) || Number.isNaN(standTime) || Number.isNaN(standTimeGoal)) {
        handleError(null, 400, 'Missing required parameter date', res);
        return;
    }

    const date = new Date(dateStr);
    if (!date) {
        handleError(null, 400, 'Could not parse date', res);
        return;
    }

    ActivitySummaryQueries.insertActivitySummary({ userId: convertUserIdToBuffer(userId), date, caloriesBurned, caloriesGoal, exerciseTime, exerciseTimeGoal, standTime, standTimeGoal })
        .then(_result => {
            res.sendStatus(200);
        })
        .catch(error => {
            handleError(error, 500, 'Unexpected error inserting data into database', res);
        });
});

export default router;