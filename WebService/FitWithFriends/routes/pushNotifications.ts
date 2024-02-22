'use strict';
const database = require('../utilities/database');
const errorHelpers = require('../utilities/errorHelpers');
const express = require('express');
const pushNotificationPlatform = require('../utilities/pushNotificationPlatform');
const router = express.Router();

router.post('/register', function (req, res) {
    const deviceToken = req.body['deviceToken'];
    const appInstallId = req.body['appInstallId'];
    const platform = req.body['platform'];

    if (!deviceToken || !appInstallId || !platform) {
        errorHelpers.handleError(null, 400, 'Missing required parameter', res);
        return;
    }

    // Currently, iOS is the only supported platform
    if (platform !== pushNotificationPlatform.iOS) {
        errorHelpers.handleError(null, 400, 'Invalid platform', res);
        return;
    }

    const userId = res.locals.oauth.token.user.id;
    const sqlHexUserId = '\\x' + userId;

    database.query('INSERT INTO push_notification_data(user_id, device_token, app_install_id, platform) \
                    VALUES ($1, $2, $3, $4) \
                    ON CONFLICT (user_id, app_install_id) DO UPDATE SET device_token = EXCLUDED.device_token, platform = EXCLUDED.platform',
                    [sqlHexUserId, deviceToken, appInstallId, platform])
        .then(function () {
            res.sendStatus(200);
        })
        .catch(function (error) {
            errorHelpers.handleError(error, 500, 'Unexpected error inserting push notification data into database', res);
        });
});

module.exports = router;