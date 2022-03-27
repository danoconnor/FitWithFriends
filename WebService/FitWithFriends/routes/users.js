'use strict';
const errorHelpers = require('../utilities/errorHelpers');
const express = require('express');
const router = express.Router();
const appleIdAuthenticationHelpers = require('../utilities/appleIdAuthenticationHelpers');
const database = require('../utilities/database');
const cryptoHelpers = require('../utilities/cryptoHelpers');
const oauthServer = require('../oauth/server');

router.get('/:userId', oauthServer.authenticate(), function (req, res) {
    if (res.locals.oauth.token.user.id !== req.params.userId) {
        // Authenticated user does not match requested user
        res.sendStatus(401)
        return
    }

    database.query('SELECT display_name from users WHERE userid = $1', [req.params.userId])
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
// The body should have the userId, firstName, lastName, idToken, and authorizationCode
// that were provided by Sign-in with Apple
router.post('/userFromAppleID', function (req, res) {
    const userId = req.body['userId'];
    const firstName = req.body['firstName'];
    const lastName = req.body['lastName'];
    const idToken = req.body['idToken'];
    const authorizationCode = req.body['authorizationCode'];

    // Validate input
    if (!userId || !userId.length ||
        !firstName || !firstName.length ||
        !lastName || !lastName.length ||
        !idToken || !idToken.length ||
        !authorizationCode || !authorizationCode.length) {
        errorHelpers.handleError(null, 400, 'Missing required parameter', res);
        return
    }

    // Validate authentication
    appleIdAuthenticationHelpers.validateIdToken(userId, idToken, authorizationCode)
        .then(isValid => {
            if (!isValid) {
                errorHelpers.handleError(null, 401, 'User token is not valid', res);
                return;
            }

            database.query('INSERT INTO users(userId, firstName, lastName) VALUES ($1, $2, $3)', [userId, firstName, lastName])
                .then(result => {
                    res.sendStatus(200);
                })
                .catch(function (error) {
                    errorHelpers.handleError(error, 500, 'Unexpected error while trying to create a new user', res)
                });
        })
        .catch(error => {
            errorHelpers.handleError(error, 500, 'Unexpected error when trying to validate token', res);
        });
});

// Create user endpoint
// Expects username, password, and displayName in the request body
// Returns bad request if the username is already in use or if the username/password do not meet a minimum length requirement
// Returns the new user's userId if the user was created successfully
router.post('/', function (req, res) {
    const username = req.body['username'];
    const password = req.body['password'];

    if (password.length < 8 || username.length < 6) {
        res.sendStatus(400);
        return;
    }

    // Usernames are not case-sensitive and are always stored in the db as lowercase
    const lowercaseUsername = username.toLowerCase();

    // Make sure that the username does not already exist
    database.query('SELECT username from users WHERE username = $1', [lowercaseUsername])
        .then(function (result) {
            if (result.length > 0) {
                // Username is taken
                res.sendStatus(400);
                return;
            }

            const displayName = req.body['displayName'];

            const salt = cryptoHelpers.getRandomString();
            const passwordHash = cryptoHelpers.getHash(password, salt);

            database.query('INSERT INTO users(username, password_hash, password_salt, display_name) VALUES ($1, $2, $3, $4) RETURNING userid', [lowercaseUsername, passwordHash, salt, displayName])
                .then(function (result) {
                    // Expect the new user's userId to be returned so we can provide it to the client
                    if (!result.length) {
                        res.sendStatus(500);
                        return;
                    }

                    res.json({
                        userId: result[0].userid
                    });
                })
                .catch(function (error) {
                    next(error);
                });
        })
        .catch(function (error) {
            next(error);
        });
});

module.exports = router;
