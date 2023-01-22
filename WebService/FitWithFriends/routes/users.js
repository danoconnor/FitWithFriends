'use strict';
const appleIdAuthenticationHelpers = require('../utilities/appleIdAuthenticationHelpers');
const database = require('../utilities/database');
const errorHelpers = require('../utilities/errorHelpers');
const express = require('express');
const oauthServer = require('../oauth/server');
const { max } = require('pg/lib/defaults');
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
        return;
    }

    // Sanity checks to make sure none of the values are too large
    const maxLength = 255;
    if (userId.length > maxLength ||
        firstName.length > maxLength ||
        lastName.length > maxLength ||
        idToken.length > maxLength) {
        errorHelpers.handleError(null, 400, 'Parameter too long', res);
        return;
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
            const currentDate = new Date();

            database.query('INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES ($1, $2, $3, $4, $5, $6)', [sqlHexUserId, firstName, lastName, 1, false, currentDate])
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
