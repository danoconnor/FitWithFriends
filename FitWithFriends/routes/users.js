'use strict';
const express = require('express');
const router = express.Router();
const database = require('../utilities/database')
const cryptoHelpers = require('../utilities/cryptoHelpers')
const oauthServer = require('../oauth/server')

/* GET users listing. */
router.get('/',  function (req, res) {
    res.send('respond with a resource');
});

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
            // TODO: log error
            res.sendStatus(500);
            return;
        });
})

// Create user endpoint
// Expects username, password, and displayName in the request body
// Returns bad request if the username is already in use or if the username/password do not meet a minimum length requirement
router.put('/', function (req, res) {
    const username = req.body['username'];
    const password = req.body['password'];

    if (password.length <= 8 || username.length <= 6) {
        res.sendStatus(400);
        return;
    }

    // Make sure that the username does not already exist
    database.query('SELECT username from users WHERE username = $1', [username])
        .then(function (result) {
            if (result.length > 0) {
                // Username is taken
                res.sendStatus(400);
                return;
            }

            const displayName = req.body['displayName'];

            const salt = cryptoHelpers.getRandomString();
            const passwordHash = cryptoHelpers.getHash(password, salt);

            database.query('INSERT INTO users(username, password_hash, password_salt, display_name) VALUES ($1, $2, $3, $4)', [username, passwordHash, salt, displayName])
                .then(function (result) {
                    // TODO: return token here so user doesn't have to login after creating account?
                    // TODO: return userId here?
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
