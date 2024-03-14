'use strict';
import { validateAppleIdToken } from '../utilities/appleIdAuthenticationHelpers';
import { handleError } from '../utilities/errorHelpers';
import express from 'express';
import { ICreateUserParams, createUser } from '../sql/users.queries';
import { convertUserIdToBuffer } from '../utilities/userHelpers';

const router = express.Router();

// Creates a user from a Sign-in with Apple
// The body should have the userId, firstName, lastName, idToken
// that were provided by Sign-in with Apple
router.post('/userFromAppleID', function (req, res) {
    const userId: string | undefined = req.body['userId'];
    const firstName: string | undefined = req.body['firstName'];
    const lastName: string | undefined = req.body['lastName'];
    const idToken: string | undefined = req.body['idToken'];

    // Validate input
    if (!userId || !userId.length ||
        !firstName || !firstName.length ||
        !lastName || !lastName.length ||
        !idToken || !idToken.length) {
        handleError(null, 400, 'Missing required parameter', res);
        return;
    }

    // Sanity checks to make sure none of the values are too large
    const maxLength = 255;
    if (userId.length > maxLength ||
        firstName.length > maxLength ||
        lastName.length > maxLength ||
        idToken.length > maxLength) {
        handleError(null, 400, 'Parameter too long', res);
        return;
    }

    // Validate authentication
    validateAppleIdToken(userId, idToken)
        .then(isValid => {
            if (!isValid) {
                handleError(null, 401, 'User token is not valid', res);
                return;
            }

            // The userId will be something like 002261.d372c8cb204940c02479ef472f717857.2341
            // We want the database to handle it as hex to save on storage space, so we'll remove the '.' chars
            // which leaves only valid hex chars remaining
            const hexUserId = userId.replace(/\./g, '');
            const currentDate = new Date();

            const createUserParams: ICreateUserParams = {
                userId: convertUserIdToBuffer(hexUserId),
                firstName: firstName,
                lastName: lastName,
                maxActiveCompetitions: 1,
                isPro: false,
                createdDate: currentDate
            };
            createUser(createUserParams)
                .then(_result => {
                    res.sendStatus(200);
                })
                .catch(function (error: Error) {
                    handleError(error, 500, 'Unexpected error while trying to create a new user', res)
                });
        })
        .catch(error => {
            handleError(error, 401, 'Token failed validation', res);
        });
});

export default router;
