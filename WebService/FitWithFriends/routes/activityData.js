'use strict';
const database = require('../utilities/database');
const express = require('express');
const router = express.Router();

router.post('/dailySummary', function (req, res) {
    const date = req.body['date'];
    var caloriesBurned = req.body['activeCaloriesBurned'];
    var caloriesGoal = req.body['activeCaloriesGoal'];
    var exerciseTime = req.body['exerciseTime'];
    var exerciseTimeGoal = req.body['exerciseTimeGoal'];
    var moveTime = req.body['moveTime'];
    var moveTimeGoal = req.body['moveTimeGoal'];
    var standTime = req.body['standTime'];
    var standTimeGoal = req.body['standTimeGoal'];

    // TODO: Other vars may be 0 - how to check that those are present?
    if (!date) {
        res.sendStatus(400);
    }

    // HACK HACK HACK
    // Users will only receive credit for reaching up to 200% of their goal for each category and any progress over that is not counted
    // We'll enforce this during insertion into the database to make the point calculation query easier
    caloriesBurned = Math.min(caloriesBurned, caloriesGoal * 2);
    exerciseTime = Math.min(exerciseTime, exerciseTimeGoal * 2);
    moveTime = Math.min(moveTime, moveTimeGoal * 2);
    standTime = Math.min(standTime, standTimeGoal * 2);

    // Another hack to make point calculation easier
    // The point calculation query will fail due to a divide by zero error if a goal is zero
    // For simplicity, we'll just set any goal that is 0 to 1 instead
    caloriesGoal = caloriesGoal > 0 ? caloriesGoal : 1;
    exerciseTimeGoal = exerciseTimeGoal > 0 ? exerciseTimeGoal : 1;
    moveTimeGoal = moveTimeGoal > 0 ? moveTimeGoal : 1;
    standTimeGoal = standTimeGoal > 0 ? standTimeGoal : 1;

    database.query('INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, move_time, move_time_goal, stand_time, stand_time_goal) \
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) \
                    ON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, move_time = EXCLUDED.move_time, move_time_goal = EXCLUDED.move_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal', 
                    [res.locals.oauth.token.user.id, date, caloriesBurned, caloriesGoal, exerciseTime, exerciseTimeGoal, moveTime, moveTimeGoal, standTime, standTimeGoal])
        .then(function (result) {
            res.sendStatus(200);
        })
});

router.post('/workout', function (req, res) {
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