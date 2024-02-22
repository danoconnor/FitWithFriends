'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
var appleIdAuthenticationHelpers_1 = require("../utilities/appleIdAuthenticationHelpers");
var database_1 = require("../utilities/database");
var errorHelpers_1 = require("../utilities/errorHelpers");
var express_1 = require("express");
var server_1 = require("../oauth/server");
var router = express_1.default.Router();
router.get('/:userId', server_1.default.authenticate(), function (req, res) {
    if (res.locals.oauth.token.user.id !== req.params.userId) {
        // Authenticated user does not match requested user
        res.sendStatus(401);
        return;
    }
    database_1.default.query('SELECT display_name from users WHERE userid = $1', ['\\x' + req.params.userId])
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
    var userId = req.body['userId'];
    var firstName = req.body['firstName'];
    var lastName = req.body['lastName'];
    var idToken = req.body['idToken'];
    // Validate input
    if (!userId || !userId.length ||
        !firstName || !firstName.length ||
        !lastName || !lastName.length ||
        !idToken || !idToken.length) {
        (0, errorHelpers_1.default)(null, 400, 'Missing required parameter', res);
        return;
    }
    // Sanity checks to make sure none of the values are too large
    var maxLength = 255;
    if (userId.length > maxLength ||
        firstName.length > maxLength ||
        lastName.length > maxLength ||
        idToken.length > maxLength) {
        errorHelpers.handleError(null, 400, 'Parameter too long', res);
        return;
    }
    // Validate authentication
    (0, appleIdAuthenticationHelpers_1.validateAppleIdToken)(userId, idToken)
        .then(function (isValid) {
        if (!isValid) {
            (0, errorHelpers_1.default)(null, 401, 'User token is not valid', res);
            return;
        }
        // The userId will be something like 002261.d372c8cb204940c02479ef472f717857.2341
        // We want the database to handle it as hex to save on storage space, so we'll remove the '.' chars
        // which leaves only valid hex chars remaining
        var hexUserId = userId.replace(/\./g, '');
        // Prefix the value with \x so the database will treat it as a hex value
        var sqlHexUserId = '\\x' + hexUserId;
        var currentDate = new Date();
        database_1.default.query('INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES ($1, $2, $3, $4, $5, $6)', [sqlHexUserId, firstName, lastName, 1, false, currentDate])
            .then(function (_result) {
            res.sendStatus(200);
        })
            .catch(function (error) {
            (0, errorHelpers_1.default)(error, 500, 'Unexpected error while trying to create a new user', res);
        });
    })
        .catch(function (error) {
        errorHelpers.handleError(error, 401, 'Token failed validation', res);
    });
});
exports.default = router;
