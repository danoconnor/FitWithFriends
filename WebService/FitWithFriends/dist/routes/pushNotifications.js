'use strict';
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const PushNotificationPlatform_1 = __importDefault(require("../utilities/PushNotificationPlatform"));
const database_1 = require("../utilities/database");
const errorHelpers_1 = require("../utilities/errorHelpers");
const PushNotificationQueries = __importStar(require("../sql/pushNotifications.queries"));
const express = __importStar(require("express"));
const userHelpers_1 = require("../utilities/userHelpers");
const router = express.Router();
// Called when the user registers for push notifications so we can save the push token for future use
// Expects the push token and the platform (an int member of PushNotificationPlatform) in the body
router.post('/register', function (req, res) {
    const pushToken = req.body['pushToken'];
    const platform = req.body['platform'];
    if (!pushToken || !platform) {
        (0, errorHelpers_1.handleError)(null, 400, 'Missing required parameter', res);
        return;
    }
    // Currently, iOS is the only supported platform
    if (platform !== PushNotificationPlatform_1.default.iOS) {
        (0, errorHelpers_1.handleError)(null, 400, 'Invalid platform', res);
        return;
    }
    const userId = res.locals.oauth.token.user.id;
    PushNotificationQueries.registerPushToken.run({ userId: (0, userHelpers_1.convertUserIdToBuffer)(userId), pushToken, platform }, database_1.DatabaseConnectionPool)
        .then(_result => {
        res.sendStatus(200);
    })
        .catch(error => {
        (0, errorHelpers_1.handleError)(error, 500, 'Unexpected error inserting push notification data into database', res);
    });
});
exports.default = router;
