'use strict';
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const appleIdAuthenticationHelpers_1 = require("../utilities/appleIdAuthenticationHelpers");
const database_1 = require("../utilities/database");
const errorHelpers_1 = require("../utilities/errorHelpers");
const express_1 = __importDefault(require("express"));
const users_queries_1 = require("../sql/users.queries");
const userHelpers_1 = require("../utilities/userHelpers");
const router = express_1.default.Router();
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
        (0, errorHelpers_1.handleError)(null, 400, 'Missing required parameter', res);
        return;
    }
    // Sanity checks to make sure none of the values are too large
    const maxLength = 255;
    if (userId.length > maxLength ||
        firstName.length > maxLength ||
        lastName.length > maxLength ||
        idToken.length > maxLength) {
        (0, errorHelpers_1.handleError)(null, 400, 'Parameter too long', res);
        return;
    }
    // Validate authentication
    (0, appleIdAuthenticationHelpers_1.validateAppleIdToken)(userId, idToken)
        .then(isValid => {
        if (!isValid) {
            (0, errorHelpers_1.handleError)(null, 401, 'User token is not valid', res);
            return;
        }
        // The userId will be something like 002261.d372c8cb204940c02479ef472f717857.2341
        // We want the database to handle it as hex to save on storage space, so we'll remove the '.' chars
        // which leaves only valid hex chars remaining
        const hexUserId = userId.replace(/\./g, '');
        const currentDate = new Date();
        const createUserParams = {
            userId: (0, userHelpers_1.convertUserIdToBuffer)(hexUserId),
            firstName: firstName,
            lastName: lastName,
            maxActiveCompetitions: 1,
            isPro: false,
            createdDate: currentDate
        };
        users_queries_1.createUser.run(createUserParams, database_1.DatabaseConnectionPool)
            .then(_result => {
            res.sendStatus(200);
        })
            .catch(function (error) {
            (0, errorHelpers_1.handleError)(error, 500, 'Unexpected error while trying to create a new user', res);
        });
    })
        .catch(error => {
        (0, errorHelpers_1.handleError)(error, 401, 'Token failed validation', res);
    });
});
exports.default = router;
