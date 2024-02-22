"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var abstract_grant_type_1 = require("oauth2-server/lib/grant-types/abstract-grant-type");
var appleIdAuthenticationHelpers_1 = require("../utilities/appleIdAuthenticationHelpers");
var invalid_argument_error_1 = require("oauth2-server/lib/errors/invalid-argument-error");
var invalid_request_error_1 = require("oauth2-server/lib/errors/invalid-request-error");
var bluebird_1 = require("bluebird");
var promisify = require('promisify-any').use(bluebird_1.default);
var util_1 = require("util");
// Constructor 
function AppleIdTokenGrant(options) {
    options = options || {};
    if (!options.model) {
        throw new invalid_argument_error_1.default('Missing parameter: `model`');
    }
    if (!options.model.saveToken) {
        throw new invalid_argument_error_1.default('Invalid argument: model does not implement `saveToken()`');
    }
    abstract_grant_type_1.default.call(this, options);
}
util_1.default.inherits(AppleIdTokenGrant, abstract_grant_type_1.default);
// This grant requires the request body to contain:
//      userId: The user ID that was provided by Apple
//      idToken: The ID token that was provided by Apple
//      scope: The requested scope for the token (for now we expect it to be `default`)
AppleIdTokenGrant.prototype.handle = function (request, client) {
    var _this = this;
    if (!request) {
        throw new invalid_argument_error_1.default('Missing parameter: `request`');
    }
    if (!client) {
        throw new invalid_argument_error_1.default('Missing parameter: `client`');
    }
    if (!request.body.userId) {
        throw new invalid_request_error_1.default('Missing parameter: `userId`');
    }
    if (!request.body.idToken) {
        throw new invalid_request_error_1.default('Missing parameter: `idToken`');
    }
    var scope = this.getScope(request);
    var userId = request.body.userId;
    var idToken = request.body.idToken;
    return (0, appleIdAuthenticationHelpers_1.validateAppleIdToken)(userId, idToken)
        .then(function (validationSuccess) {
        if (!validationSuccess) {
            throw new invalid_request_error_1.default('Token validation failed');
        }
        // The userId will be something like 002261.d372c8cb204940c02479ef472f717857.2341
        // We want the database to handle it as hex to save on storage space, so we'll remove the '.' chars
        // which leaves only valid hex chars remaining
        var hexUserId = userId.replace(/\./g, '');
        return _this.saveToken({ id: hexUserId }, client, scope);
    });
};
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
