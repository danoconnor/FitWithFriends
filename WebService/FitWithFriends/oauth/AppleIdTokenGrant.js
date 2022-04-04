const AbstractGrantType = require('oauth2-server/lib/grant-types/abstract-grant-type');
const appleIdAuthenticationHelpers = require('../utilities/appleIdAuthenticationHelpers');
const InvalidArgumentError = require('oauth2-server/lib/errors/invalid-argument-error');
const InvalidRequestError = require('oauth2-server/lib/errors/invalid-request-error');
const Promise = require('bluebird');
const promisify = require('promisify-any').use(Promise);
const util = require('util');

// Constructor 

function AppleIdTokenGrant(options) {
    options = options || {};

    if (!options.model) {
        throw new InvalidArgumentError('Missing parameter: `model`');
    }

    if (!options.model.saveToken) {
        throw new InvalidArgumentError('Invalid argument: model does not implement `saveToken()`');
    }

    AbstractGrantType.call(this, options);
}

util.inherits(AppleIdTokenGrant, AbstractGrantType);

// This grant requires the request body to contain:
//      userId: The user ID that was provided by Apple
//      idToken: The ID token that was provided by Apple
//      scope: The requested scope for the token (for now we expect it to be `default`)
AppleIdTokenGrant.prototype.handle = function (request, client) {
    if (!request) {
        throw new InvalidArgumentError('Missing parameter: `request`');
    }

    if (!client) {
        throw new InvalidArgumentError('Missing parameter: `client`');
    }

    if (!request.body.userId) {
        throw new InvalidRequestError('Missing parameter: `userId`');
    }

    if (!request.body.idToken) {
        throw new InvalidRequestError('Missing parameter: `idToken`');
    }

    const scope = this.getScope(request);

    const userId = request.body.userId;
    const idToken = request.body.idToken;

    return appleIdAuthenticationHelpers.validateIdToken(userId, idToken)
        .then(validationSuccess => {
            if (!validationSuccess) {
                throw new InvalidRequestError('Token validation failed');
            }

            // The userId will be something like 002261.d372c8cb204940c02479ef472f717857.2341
            // We want the database to handle it as hex to save on storage space, so we'll remove the '.' chars
            // which leaves only valid hex chars remaining
            const hexUserId = userId.replace(/\./g, '');

            return this.saveToken(hexUserId, client, scope);
        })
}

// Based on the password grant implementation here: https://github.com/oauthjs/node-oauth2-server/blob/91d2cbe70a0eddc53d72def96864e2de0fd41703/lib/grant-types/password-grant-type.js
AppleIdTokenGrant.prototype.saveToken = function (user, client, scope) {
    var fns = [
        this.validateScope(user, client, scope),
        this.generateAccessToken(client, user, scope),
        this.generateRefreshToken(client, user, scope),
        this.getAccessTokenExpiresAt(),
        this.getRefreshTokenExpiresAt()
    ];

    return Promise.all(fns)
        .bind(this)
        .spread(function (scope, accessToken, refreshToken, accessTokenExpiresAt, refreshTokenExpiresAt) {
            var token = {
                accessToken: accessToken,
                accessTokenExpiresAt: accessTokenExpiresAt,
                refreshToken: refreshToken,
                refreshTokenExpiresAt: refreshTokenExpiresAt,
                scope: scope  
            };

            return promisify(this.model.saveToken, 3).call(this.model, token, client, user);
        });
};

module.exports = AppleIdTokenGrant;