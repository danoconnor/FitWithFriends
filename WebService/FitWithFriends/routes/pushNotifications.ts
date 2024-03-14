'use strict';
import PushNotificationPlatform from '../utilities/PushNotificationPlatform';
import { DatabaseConnectionPool } from '../utilities/database';
import { handleError } from '../utilities/errorHelpers';
import * as PushNotificationQueries from '../sql/pushNotifications.queries';
import * as express from 'express';
import { convertUserIdToBuffer } from '../utilities/userHelpers';
const router = express.Router();

const uuidRegex = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/;

// Called when the user registers for push notifications so we can save the push token for future use
// Expects the push token and the platform (an int member of PushNotificationPlatform) in the body
router.post('/register', function (req, res) {
    const pushToken: string = req.body['pushToken'];
    const platform: number = req.body['platform'];
    const appInstallId: string = req.body['appInstallId'];

    if (!pushToken || !pushToken.length || !platform || !appInstallId || !appInstallId.length) {
        handleError(null, 400, 'Missing required parameter', res);
        return;
    }

    // Make sure the appInstallId is a valid UUID
    if (!uuidRegex.test(appInstallId)) {
        handleError(null, 400, 'Invalid UUID', res);
        return;
    }

    // Currently, iOS is the only supported platform
    if (platform !== PushNotificationPlatform.iOS) {
        handleError(null, 400, 'Invalid platform', res);
        return;
    }

    const userId = res.locals.oauth.token.user.id;
    PushNotificationQueries.registerPushToken({ userId: convertUserIdToBuffer(userId), pushToken, platform, appInstallId })
        .then(_result => {
            res.sendStatus(200);
        })
        .catch(error => {
            handleError(error, 500, 'Unexpected error inserting push notification data into database', res);
        });
});

export default router;