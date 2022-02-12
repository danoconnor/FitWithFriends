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

    if (!startDate || !endDate || !displayName) {
        res.sendStatus(400);
        return;
    }

    // Generate an access code for this competition so users can be added
    const accessToken = cryptoHelpers.getRandomToken();

    database.query('INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token) VALUES ($1, $2, $3, $4, $5) RETURNING competition_id',
        [startDate, endDate, displayName, res.locals.oauth.token.user.id, accessToken])
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
    database.query('SELECT competition_id FROM competitions WHERE access_token = $1', accessToken)
        .then(function (result) {
            if (!result.length) {
                res.sendStatus(404);
                return;
            }

            const competitionId = result[0].competition_id;

            // TODO: remove when multiple competitions are supported
            // Check that the user has not already joined a competition yet
            database.query('SELECT COUNT(competitionid) FROM users_competitions WHERE userid = $1', res.locals.oauth.token.user.id)
                .then(function (result) {
                    if (!result.length || result[0].count > 0) {
                        res.sendStatus(400);
                        return;
                    }

                    // Add the user to the competition
                    database.query('INSERT INTO users_competitions VALUES ($1, $2) \
                            ON CONFLICT (userid, competitionid) DO NOTHING', [res.locals.oauth.token.user.id, competitionId])
                        .then(function (result) {
                            res.sendStatus(200);
                        })
                })
        })
});

// Leave competition endpoint
// Expects a userId and a competitionId in the request body
// The user will be removed from the competition if the currently authenticated user matches the user to remove
// OR the currently authenticated user is the admin of the competition
router.post('/leave', function (req, res) {
    const targetUserId = req.body['userId'];
    const competitionId = req.body['competitionId'];
    if (!targetUserId || !competitionId) {
        res.sendStatus(400);
        return;
    }

    if (targetUserId === res.locals.oauth.token.user.id) {
        selfRemoveUser(req, res, targetUserId, competitionId);
    } else {
        // This func will validate that the current user is the admin of the competition
        adminRemoveUser(req, res, targetUserId, competitionId);
    }
});

// Returns an overview of the given competition that contains a list of users and their current points for the competition
router.get('/:competitionId/overview', function (req, res) {
    // 1. Get the competition data and the users
    Promise.all([
        database.query('SELECT userid FROM users_competitions WHERE competitionid = $1', [req.params.competitionId]),
        database.query('SELECT competition_id, start_date, end_date, display_name FROM competitions WHERE competition_id = $1', [req.params.competitionId])
    ])
    .then(function (result) {
        if (result.length < 2) {
            res.sendStatus(500);
            return;
        }

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

        // 3. Calculate points for the activity data for all of the users in the competition in the competition date range

        const userIdList = usersCompetitionsResult.map(row => row.userid).join();
        const competitionInfo = competitionsResult[0];

        var query = '';
        var queryParams = [];

        // If the competition is currently active, then include each user's activity points so far today in the results
        let currentDate = new Date();
        if (currentDate >= competitionInfo.start_date && currentDate <= competitionInfo.end_date) {
            queryParams = [competitionInfo.start_date, competitionInfo.end_date, currentDate];
            query = 'SELECT activitySummaryData.user_id, display_name, activity_points, daily_points FROM \
                    (SELECT userid, display_name FROM users WHERE userid in (' + userIdList + ')) AS userInfo \
                    INNER JOIN \
                        (SELECT user_id, SUM(daily_points) AS activity_points \
                        FROM activity_summaries \
                        WHERE date >= $1 and date <= $2 and user_id in (' + userIdList + ') \
                        GROUP BY user_id) AS activitySummaryData \
                        FULL OUTER JOIN \
                            (SELECT user_id, daily_points \
                            FROM activity_summaries \
                            WHERE date = $3 and user_id in (' + userIdList + ')) AS today_points \
                            ON activitySummaryData.user_id = today_points.user_id \
                    ON activitySummaryData.user_id = userInfo.userid';
        } else {
            queryParams = [competitionInfo.start_date, competitionInfo.end_date];
            query = 'SELECT user_id, display_name, activity_points FROM \
                    (SELECT userid, display_name FROM users WHERE userid in (' + userIdList + ')) AS userInfo \
                    INNER JOIN \
                        (SELECT user_id, SUM(daily_points) AS activity_points \
                        FROM activity_summaries \
                        WHERE date >= $1 and date <= $2 and user_id in (' + userIdList + ') \
                        GROUP BY user_id) AS activitySummaryData \
                    ON activitySummaryData.user_id = userInfo.userid';
        }

        database.query(query, queryParams)
            .then(function (result) {
                res.json({
                    'competitionId': competitionInfo.competition_id,
                    'competitionName': competitionInfo.display_name,
                    'competitionStart': competitionInfo.start_date,
                    'competitionEnd': competitionInfo.end_date,
                    'currentResults': result
                });
            })
            .catch(function (error) {
                const errorMessage = 'Error getting competitionId ' + req.params.competitionId + '. Error: ' + error;
                res.send(errorMessage);
                res.send(500);
            })
    })
    .catch(function (error) {
        error.status = 500;
        error.message = 'Error getting competitionId ' + req.params.competitionId + '. Error: ' + error;
        res.sendStatus(error.status);
    })
});

module.exports = router;

// Helper functions

// Called when the admin of the competition is removing another user from the competition
function adminRemoveUser(req, res, targetUserId, competitionId) {
    // Need to check that the current user is the admin of the competition
    database.query('SELECT COUNT(competition_id) FROM competitions WHERE admin_user_id = $1 AND competition_id = $2', [res.locals.oauth.token.user.id, competitionId])
        .then(function (result) {
            if (!result.length || result[0].count != 1) {
                res.sendStatus(401);
                return;
            }

            database.query('DELETE FROM users_competitions WHERE userid = $1 AND competitionid = $2', [targetUserId, competitionId])
                .then(function (result) {
                    res.sendStatus(200);
                })
                .catch(function (error) {
                    next(error);
                })
        })
        .catch(function (error) {
            next(error);
        })
}

// Called when a user is trying to remove theirself from the competition
function selfRemoveUser(req, res, targetUserId, competitionId) {
    if (targetUserId !== res.locals.oauth.token.user.id) {
        res.sendStatus(401);
        return;
    }

    database.query('DELETE FROM users_competitions WHERE userid = $1 AND competitionid = $2', [res.locals.oauth.token.user.id, competitionId])
        .then(function (result) {
            res.sendStatus(200);
        })
}