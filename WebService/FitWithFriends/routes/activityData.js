'use strict';
const database = require('../utilities/database');
const express = require('express');
const router = express.Router();

// Users can only score a maximum of 600 points per day
const maxPointsPerDay = 600;

router.post('/dailySummary', function (req, res) {
    const date = req.body['date'];
    const caloriesBurned = req.body['activeCaloriesBurned'];
    const caloriesGoal = req.body['activeCaloriesGoal'];
    const exerciseTime = req.body['exerciseTime'];
    const exerciseTimeGoal = req.body['exerciseTimeGoal'];
    const standTime = req.body['standTime'];
    const standTimeGoal = req.body['standTimeGoal'];

    // TODO: Other vars may be 0 - how to check that those are present?
    if (!date) {
        res.sendStatus(400);
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
    const dailyPoints = Math.min(caloriePoints + exercisePoints + standPoints, maxPointsPerDay);

    database.query('INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal, daily_points) \
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) \
                    ON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal, daily_points = EXCLUDED.daily_points', 
                    [res.locals.oauth.token.user.id, date, caloriesBurned, caloriesGoal, exerciseTime, exerciseTimeGoal, standTime, standTimeGoal, dailyPoints])
        .then(function (result) {
            res.sendStatus(200);
        })
});

router.post('/workout', function (req, res) {
    // TODO: For the MVR we are limiting activity data to only the daily summaries
    // We will re-enable the workout data in the future
    res.sendStatus(404);
    return;
    
    const startDate = req.body['startDate'];
    const duration = req.body['duration'];
    const caloriesBurned = req.body['caloriesBurned'];
    const activityType = req.body['activityTypeRawValue'];
    const distance = req.body['distance'];

    // TODO: Other vars may be 0 - how to check that those are present?
    if (!startDate) {
        res.sendStatus(400);
    }

    // We will try to avoid sending duplicate data from the client, but as a backup
    // the workout_data table has all four columns set as the primary key so duplicate data cannot be entered
    database.query('INSERT INTO workout_data(user_id, start_date, duration, calories_burned, activity_type, distance) \
                    VALUES ($1, $2, $3, $4, $5, $6) \
                    ON CONFLICT (user_id, start_date, duration, calories_burned) DO NOTHING', [res.locals.oauth.token.user.id, startDate, duration, caloriesBurned, activityType, distance])
        .then(function (result) {
            res.sendStatus(200);
        })
});

module.exports = router;