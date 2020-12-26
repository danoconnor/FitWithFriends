'use strict';
const database = require('../utilities/database');
const express = require('express');
const router = express.Router();

router.post('/dailySummary', function (req, res) {
    const date = req.body['date'];
    const caloriesBurned = req.body['activeCaloriesBurned'];
    const caloriesGoal = req.body['activeCaloriesGoal'];
    const exerciseTime = req.body['exerciseTime'];
    const exerciseTimeGoal = req.body['exerciseTimeGoal'];
    const moveTime = req.body['moveTime'];
    const moveTimeGoal = req.body['moveTimeGoal'];
    const standTime = req.body['standTime'];
    const standTimeGoal = req.body['standTimeGoal'];

    // TODO: Other vars may be 0 - how to check that those are present?
    if (!date) {
        res.sendStatus(400);
    }

    database.query('INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, move_time, move_time_goal, stand_time, stand_time_goal) \
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) \
                    ON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, move_time = EXCLUDED.move_time, move_time_goal = EXCLUDED.move_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal', 
                    [res.locals.oauth.token.user.id, date, caloriesBurned, caloriesGoal, exerciseTime, exerciseTimeGoal, moveTime, moveTimeGoal, standTime, standTimeGoal])
        .then(function (result) {
            res.sendStatus(200);
        })
        .catch(function (error) {
            // TODO: log error
            res.sendStatus(500);
            return;
        });
});

router.post('/workout', function (req, res) {
    const startDate = req.body['startDate'];
    const duration = req.body['duration'];
    const caloriesBurned = req.body['caloriesBurned'];

    // TODO: Other vars may be 0 - how to check that those are present?
    if (!startDate) {
        res.sendStatus(400);
    }

    database.query('INSERT INTO workout_data(user_id, start_date, duration, calories_burned) VALUES ($1, $2, $3, $4)', [res.locals.oauth.token.user.id, startDate, duration, caloriesBurned])
        .then(function (result) {
            res.sendStatus(200);
        })
        .catch(function (error) {
            // TODO: log error
            res.sendStatus(500);
            return;
        });
});

module.exports = router;