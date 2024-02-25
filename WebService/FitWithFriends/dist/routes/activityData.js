'use strict';
var database = require('../utilities/database');
var errorHelpers = require('../utilities/errorHelpers');
var express = require('express');
var router = express.Router();
// Users can only score a maximum of 600 points per day
var maxPointsPerDay = 600;
router.post('/dailySummary', function (req, res) {
    var dateStr = req.body['date'];
    var caloriesBurned = req.body['activeCaloriesBurned'];
    var caloriesGoal = req.body['activeCaloriesGoal'];
    var exerciseTime = req.body['exerciseTime'];
    var exerciseTimeGoal = req.body['exerciseTimeGoal'];
    var standTime = req.body['standTime'];
    var standTimeGoal = req.body['standTimeGoal'];
    // Prefix the value with \x so the database will treat it as a hex value
    var userId = res.locals.oauth.token.user.id;
    var sqlHexUserId = '\\x' + userId;
    // TODO: Other vars may be 0 - how to check that those are present?
    if (!dateStr) {
        errorHelpers.handleError(null, 400, 'Missing required parameter date', res);
        return;
    }
    var date = new Date(dateStr);
    if (!date) {
        errorHelpers.handleError(null, 400, 'Could not parse date', res);
        return;
    }
    var caloriePoints = 0;
    var exercisePoints = 0;
    var standPoints = 0;
    // Avoid divide-by-zero errors
    if (caloriesGoal > 0) {
        caloriePoints = caloriesBurned / caloriesGoal * 100;
    }
    if (exerciseTimeGoal > 0) {
        exercisePoints = exerciseTime / exerciseTimeGoal * 100;
    }
    if (standTimeGoal > 0) {
        standPoints = standTime / standTimeGoal * 100;
    }
    // Make sure users don't score more than the maximum amount of points per day
    var dailyPoints = Math.min(caloriePoints + exercisePoints + standPoints, maxPointsPerDay);
    database.query('INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal, daily_points) \
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) \
                    ON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal, daily_points = EXCLUDED.daily_points', [sqlHexUserId, date.toUTCString(), caloriesBurned, caloriesGoal, exerciseTime, exerciseTimeGoal, standTime, standTimeGoal, dailyPoints])
        .then(function (result) {
        res.sendStatus(200);
    })
        .catch(function (error) {
        errorHelpers.handleError(error, 500, 'Unexpected error inserting data into database', res);
    });
});
module.exports = router;
