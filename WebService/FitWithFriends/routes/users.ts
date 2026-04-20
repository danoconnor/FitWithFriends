'use strict';
import { validateAppleIdToken } from '../utilities/appleIdAuthenticationHelpers';
import { handleError } from '../utilities/errorHelpers';
import express from 'express';
import { ICreateUserParams, createUser, deleteUser } from '../sql/users.queries';
import { convertUserIdToBuffer } from '../utilities/userHelpers';
import oauthServer from '../oauth/server';

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
        lastName.length > maxLength) {
        handleError(null, 400, 'Parameter too long', res);
        return;
    }

    // Apple ID tokens are JWTs which can exceed 255 chars, so we apply a separate upper bound
    if (idToken.length > 4096) {
        handleError(null, 400, 'idToken too long', res);
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

// Deletes the currently authenticated user's account and all associated data
router.delete('/me', oauthServer.authenticate(), function (req, res) {
    const userId: string = res.locals.oauth.token.user.id;
    const userIdBuffer = convertUserIdToBuffer(userId);

    deleteUser({ userId: userIdBuffer })
        .then(() => res.sendStatus(200))
        .catch((error: Error) => handleError(error, 500, 'Unexpected error while deleting user', res));
});

export default router;
