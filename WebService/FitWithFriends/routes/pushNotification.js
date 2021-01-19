'use strict';
const database = require('../utilities/database');
const express = require('express');
const router = express.Router();

router.post('/register', function (req, res) {
    const pushToken = req.body['pushToken'];
    if (!pushToken) {
        res.sendStatus(400);
        return;
    }

    // TODO: when multiple platforms are supported, take a platform name as a query param and map it to an enum
    // For now, I'll just hardcode Apple = 1
    const platform = 1;

    database.query('INSERT INTO push_tokens(user_id, token, platform) VALUES ($1, $2, $3)', [res.locals.oauth.token.user.id, pushToken, platform])
        .then(function (result) {
            res.sendStatus(200);
        })
});

module.exports = router;