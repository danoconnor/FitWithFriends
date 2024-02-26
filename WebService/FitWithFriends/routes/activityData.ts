'use strict';
import { handleError } from "../utilities/errorHelpers";
import * as ActivitySummaryQueries from "../sql/activitySummaries.queries";
import { DatabaseConnectionPool } from "../utilities/database";
import * as express from "express";
const router = express.Router();

router.post('/dailySummary', function (req, res) {
    const dateStr: string = req.body['date'];
    const caloriesBurned: number = req.body['activeCaloriesBurned'];
    const caloriesGoal: number = req.body['activeCaloriesGoal'];
    const exerciseTime: number = req.body['exerciseTime'];
    const exerciseTimeGoal: number = req.body['exerciseTimeGoal'];
    const standTime: number = req.body['standTime'];
    const standTimeGoal: number = req.body['standTimeGoal'];

    const userId = res.locals.oauth.token.user.id;

    // TODO: Other vars may be 0 - how to check that those are present?
    if (!dateStr) {
        handleError(null, 400, 'Missing required parameter date', res);
        return;
    }

    const date = new Date(dateStr);
    if (!date) {
        handleError(null, 400, 'Could not parse date', res);
        return;
    }

    ActivitySummaryQueries.insertActivitySummary.run({ userId, date, caloriesBurned, caloriesGoal, exerciseTime, exerciseTimeGoal, standTime, standTimeGoal }, DatabaseConnectionPool)
        .then(_result => {
            res.sendStatus(200);
        })
        .catch(error => {
            handleError(error, 500, 'Unexpected error inserting data into database', res);
        });
});

export default router;