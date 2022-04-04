'use strict';
const appleIdAuthenticationHelpers = require('../utilities/appleIdAuthenticationHelpers');
const database = require('../utilities/database');
const errorHelpers = require('../utilities/errorHelpers');
const express = require('express');
const oauthServer = require('../oauth/server');
const router = express.Router();

router.get('/:userId', oauthServer.authenticate(), function (req, res) {
    if (res.locals.oauth.token.user.id !== req.params.userId) {
        // Authenticated user does not match requested user
        res.sendStatus(401)
        return
    }

    database.query('SELECT display_name from users WHERE userid = $1', ['\\x' + req.params.userId])
        .then(function (result) {
            if (!result.length) {
                res.sendStatus(404);
                return;
            }

            res.json(result);
        })
        .catch(function (error) {
            next(error);
        });
});

// Creates a user from a Sign-in with Apple
// The body should have the userId, firstName, lastName, idToken
// that were provided by Sign-in with Apple
router.post('/userFromAppleID', function (req, res) {
    const userId = req.body['userId'];
    const firstName = req.body['firstName'];
    const lastName = req.body['lastName'];
    const idToken = req.body['idToken'];

    // Validate input
    if (!userId || !userId.length ||
        !firstName || !firstName.length ||
        !lastName || !lastName.length ||
        !idToken || !idToken.length) {
        errorHelpers.handleError(null, 400, 'Missing required parameter', res);
        return
    }

    // Validate authentication
    appleIdAuthenticationHelpers.validateIdToken(userId, idToken)
        .then(isValid => {
            if (!isValid) {
                errorHelpers.handleError(null, 401, 'User token is not valid', res);
                return;
            }

            // The userId will be something like 002261.d372c8cb204940c02479ef472f717857.2341
            // We want the database to handle it as hex to save on storage space, so we'll remove the '.' chars
            // which leaves only valid hex chars remaining
            const hexUserId = userId.replace(/\./g, '');

            // Prefix the value with \x so the database will treat it as a hex value
            const sqlHexUserId = '\\x' + hexUserId;

            database.query('INSERT INTO users(user_id, first_name, last_name) VALUES ($1, $2, $3)', [sqlHexUserId, firstName, lastName])
                .then(result => {
                    res.sendStatus(200);
                })
                .catch(function (error) {
                    errorHelpers.handleError(error, 500, 'Unexpected error while trying to create a new user', res)
                });
        })
        .catch(error => {
            errorHelpers.handleError(error, 401, 'Token failed validation', res);
        });
});

module.exports = router;
