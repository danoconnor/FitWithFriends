'use strict';
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var appleIdAuthenticationHelpers_1 = require("../utilities/appleIdAuthenticationHelpers");
var database_1 = require("../utilities/database");
var errorHelpers_1 = require("../utilities/errorHelpers");
var express_1 = __importDefault(require("express"));
var users_queries_1 = require("../sql/users.queries");
var userHelpers_1 = require("../utilities/userHelpers");
var router = express_1.default.Router();
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
        (0, errorHelpers_1.handleError)(null, 400, 'Missing required parameter', res);
        return;
    }
    // Sanity checks to make sure none of the values are too large
    var maxLength = 255;
    if (userId.length > maxLength ||
        firstName.length > maxLength ||
        lastName.length > maxLength ||
        idToken.length > maxLength) {
        (0, errorHelpers_1.handleError)(null, 400, 'Parameter too long', res);
        return;
    }
    // Validate authentication
    (0, appleIdAuthenticationHelpers_1.validateAppleIdToken)(userId, idToken)
        .then(function (isValid) {
        if (!isValid) {
            (0, errorHelpers_1.handleError)(null, 401, 'User token is not valid', res);
            return;
        }
        // The userId will be something like 002261.d372c8cb204940c02479ef472f717857.2341
        // We want the database to handle it as hex to save on storage space, so we'll remove the '.' chars
        // which leaves only valid hex chars remaining
        var hexUserId = userId.replace(/\./g, '');
        var currentDate = new Date();
        var createUserParams = {
            userId: (0, userHelpers_1.convertUserIdToBuffer)(hexUserId),
            firstName: firstName,
            lastName: lastName,
            maxActiveCompetitions: 1,
            isPro: false,
            createdDate: currentDate
        };
        users_queries_1.createUser.run(createUserParams, database_1.DatabaseConnectionPool)
            .then(function (_result) {
            res.sendStatus(200);
        })
            .catch(function (error) {
            (0, errorHelpers_1.handleError)(error, 500, 'Unexpected error while trying to create a new user', res);
        });
    })
        .catch(function (error) {
        (0, errorHelpers_1.handleError)(error, 401, 'Token failed validation', res);
    });
});
exports.default = router;
