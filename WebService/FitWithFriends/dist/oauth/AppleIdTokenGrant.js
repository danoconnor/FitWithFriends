"use strict";
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
var oauth2_server_1 = require("@node-oauth/oauth2-server");
var appleIdAuthenticationHelpers_1 = require("../utilities/appleIdAuthenticationHelpers");
// Constructor 
var AppleIdTokenGrant = /** @class */ (function (_super) {
    __extends(AppleIdTokenGrant, _super);
    function AppleIdTokenGrant(options) {
        var _this = _super.call(this, options) || this;
        _this.model = options.model;
        return _this;
    }
    AppleIdTokenGrant.prototype.handle = function (request, client) {
        var _this = this;
        if (!request.body.userId) {
            throw new oauth2_server_1.InvalidRequestError('Missing parameter: `userId`');
        }
        if (!request.body.idToken) {
            throw new oauth2_server_1.InvalidRequestError('Missing parameter: `idToken`');
        }
        var scope = this.getScope(request);
        var userId = request.body.userId;
        var idToken = request.body.idToken;
        return (0, appleIdAuthenticationHelpers_1.validateAppleIdToken)(userId, idToken)
            .then(function (validationSuccess) {
            if (!validationSuccess) {
                throw new oauth2_server_1.InvalidRequestError('Token validation failed');
            }
            // The userId will be something like 002261.d372c8cb204940c02479ef472f717857.2341
            // We want the database to handle it as hex to save on storage space, so we'll remove the '.' chars
            // which leaves only valid hex chars remaining
            var hexUserId = userId.replace(/\./g, '');
            return _this.saveToken({ id: hexUserId }, client, scope);
        });
    };
    AppleIdTokenGrant.prototype.saveToken = function (user, client, requestedScope) {
        var _this = this;
        var fns = [
            this.validateScope(user, client, requestedScope),
            this.generateAccessToken(client, user, requestedScope),
            this.generateRefreshToken(client, user, requestedScope),
            this.getAccessTokenExpiresAt(),
            this.getRefreshTokenExpiresAt()
        ];
        return Promise.all(fns)
            .then(function (_a) {
            var validatedScope = _a[0], accessToken = _a[1], refreshToken = _a[2], accessTokenExpiresAt = _a[3], refreshTokenExpiresAt = _a[4];
            if (validatedScope === false) {
                throw new oauth2_server_1.InvalidRequestError('Invalid scope: Requested scope is invalid');
            }
            var token = {
                client: client,
                user: user,
                accessToken: accessToken,
                accessTokenExpiresAt: accessTokenExpiresAt,
                refreshToken: refreshToken,
                refreshTokenExpiresAt: refreshTokenExpiresAt,
                scope: validatedScope
            };
            return _this.model.saveToken(token, client, user);
        });
    };
    return AppleIdTokenGrant;
}(oauth2_server_1.AbstractGrantType));
exports.default = AppleIdTokenGrant;
