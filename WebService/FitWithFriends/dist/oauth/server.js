"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var express_oauth_server_1 = __importDefault(require("@node-oauth/express-oauth-server"));
var AppleIdTokenGrant_1 = __importDefault(require("./AppleIdTokenGrant"));
var model_1 = __importDefault(require("./model"));
// Note: our custom apple_id_token grant type replaces the password grant
// because our app currently only supports Sign-In With Apple authentication
var server = new express_oauth_server_1.default({
    model: new model_1.default(),
    extendedGrantTypes: { 'apple_id_token': AppleIdTokenGrant_1.default },
    accessTokenLifetime: 60 * 60, // 1 hour
    refreshTokenLifetime: 60 * 60 * 24 * 365, // 1 year
    allowEmptyState: true,
    allowExtendedTokenAttributes: true,
    alwaysIssueNewRefreshToken: false
});
exports.default = server;
