'use strict';
const express = require('express');
const router = express.Router();
const database = require('../utilities/database');
const cryptoHelpers = require('../utilities/cryptoHelpers');


// Returns the competitionIds that the currently authenticated user is a member of
router.get('/', function (req, res) {
    database.query('SELECT competitionid from users_competitions WHERE userid = $1', [res.locals.oauth.token.user.id])
        .then(function (result) {
            const competitionIds = result.map(obj => parseInt(obj.competitionid));
            res.json(competitionIds);
        })
});

// Create new competition. The currently authenticated user will become the admin for the competition.
// The request should have startDate, endDate, and displayName values
router.post('/', function (req, res) {
    const startDate = new Date(req.body['startDate']);
    const endDate = new Date(req.body['endDate']);
    const displayName = req.body['displayName'];
    const workoutsOnly = req.body['workoutsOnly'];

    if (!startDate || !endDate || !displayName) {
        res.sendStatus(400);
        return;
    }

    // Generate an access code for this competition so users can be added
    const accessToken = cryptoHelpers.getRandomToken();

    database.query('INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, workouts_only) VALUES ($1, $2, $3, $4, $5, $6) RETURNING competition_id',
        [startDate, endDate, displayName, res.locals.oauth.token.user.id, accessToken, workoutsOnly])
        .then(function (result) {
            if (!result.length) {
                res.sendStatus(500);
                return
            }

            const competitionId = result[0].competition_id

            // Add the admin user to the competition
            database.query('INSERT INTO users_competitions VALUES ($1, $2)', [res.locals.oauth.token.user.id, competitionId])
                .then(function (result) {
                    res.json({
                        'competition_id': competitionId,
                        'accessCode': accessToken
                    });
                })
        })
});

// Join existing competition endpoint - adds the currently authenticated user to the competition that matches the given token
// Expects a competition access token in the request body
router.post('/join', function (req, res) {
    const accessToken = req.body['accessToken'];
    if (!accessToken) {
        res.sendStatus(400);
        return;
    }

    // Find matching competition and validate access token
    database.query('SELECT competition_id from competitions WHERE access_token = $1', accessToken)
        .then(function (result) {
            if (!result.length) {
                res.sendStatus(404);
                return;
            }

            const competitionId = result[0].competition_id;
            database.query('INSERT INTO users_competitions VALUES ($1, $2) \
                            ON CONFLICT (userid, competitionid) DO NOTHING', [res.locals.oauth.token.user.id, competitionId])
                .then(function (result) {
                    res.sendStatus(200);
                })
        })
});

// Returns an overview of the given competition that contains a list of users and their current points for the competition
router.get('/:competitionId/overview', function (req, res) {
    // 1. Get the competition data and the users
    Promise.all([
        database.query('SELECT userid FROM users_competitions WHERE competitionid = $1', [req.params.competitionId]),
        database.query('SELECT competition_id, start_date, end_date, display_name, workouts_only FROM competitions WHERE competition_id = $1', [req.params.competitionId])
        ]
    )
    .then(function (result) {
        const usersCompetitionsResult = result[0];
        const competitionsResult = result[1];

        if (!usersCompetitionsResult.length || !competitionsResult.length) {
            res.sendStatus(404);
            return;
        }

        // 2. Check that the authenticated user is one of the members of this competition
        if (!usersCompetitionsResult.filter(function (row) { return row.userid === res.locals.oauth.token.user.id }).length) {
            res.sendStatus(401);
            return;
        }

        // 3. Calculate points for the workout/activity data for all of the users in the competition in the competition date range
        
        const userIdList = usersCompetitionsResult.map(row => row.userid).join();
        const competitionInfo = competitionsResult[0];

        // Workout points = duration (in minutes) + calories_burned
        // Activity points = calories goal % + exercise time goal % + move time goal % + stand time goal %
        // Note: points for each category are capped at 100, which is enforced when the row is inserted by artificially setting the real value to match the goal when necessary
        var query = '';
        if (competitionInfo.workouts_only) {
            query = 'SELECT user_id, display_name, workout_points FROM \
                         (SELECT userid, display_name FROM users WHERE userid in (' + userIdList + ')) AS userInfo \
                     INNER JOIN \
                         (SELECT user_id, SUM((duration / 60) + calories_burned) AS workout_points \
                         FROM workout_data \
                         WHERE start_date >= $1 and start_date <= $2 and user_id in (' + userIdList + ') \
                         GROUP BY user_id) AS workoutData \
                     ON workoutData.user_id = userInfo.userid';
        } else {
            query = 'SELECT user_id, display_name, workout_points, activity_points FROM \
                         (SELECT userid, display_name FROM users WHERE userid in (' + userIdList + ')) AS userInfo \
                     INNER JOIN \
                         (SELECT workoutData.user_id AS user_id, workout_points, activity_points FROM \
                             (SELECT user_id, SUM((duration / 60) + calories_burned) AS workout_points \
                             FROM workout_data \
                             WHERE start_date >= $1 and start_date <= $2 and user_id in (' + userIdList + ') \
                             GROUP BY user_id) AS workoutData \
                         FULL OUTER JOIN \
                             (SELECT user_id, SUM((calories_burned / calories_goal * 100) + (exercise_time / exercise_time_goal * 100) + (move_time / move_time_goal * 100) + (stand_time / stand_time_goal * 100)) AS activity_points \
                             FROM activity_summaries \
                             WHERE date >= $1 and date <= $2 and user_id in (' + userIdList + ') \
                             GROUP BY user_id) AS activitySummaryData \
                         ON workoutData.user_id = activitySummaryData.user_id) AS pointData \
                     ON pointData.user_id = userInfo.userid';
        }

        database.query(query, [competitionInfo.start_date, competitionInfo.end_date])
            .then(function (result) {
                res.json({
                    'competitionId': competitionInfo.competition_id,
                    'competitionName': competitionInfo.display_name,
                    'competitionStart': competitionInfo.start_date,
                    'competitionEnd': competitionInfo.end_date,
                    'currentResults': result
                });
            })
    })
});

module.exports = router;