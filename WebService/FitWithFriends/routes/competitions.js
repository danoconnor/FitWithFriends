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
        .catch(function (error) {
            // TODO: log error
            res.sendStatus(500);
            return;
        });
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
                .catch(function (error) {
                    // TODO: log error
                    res.sendStatus(500);
                    return;
                });
        })
        .catch(function (error) {
            // TODO: log error
            res.sendStatus(500);
            return;
        });
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
            database.query('INSERT INTO users_competitions VALUES ($1, $2)', [res.locals.oauth.token.user.id, competitionId])
                .then(function (result) {
                    res.sendStatus(200);
                })
                .catch(function (error) {
                    // TODO: log error
                    res.sendStatus(500);
                    return;
                });
        })
        .catch(function (error) {
            // TODO: log error
            res.sendStatus(500);
            return;
        });
});

module.exports = router;