"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteRefreshToken = exports.saveRefreshToken = exports.getRefreshToken = exports.getClient = void 0;
/** Types generated for queries found in "sql/oauth.sql" */
var runtime_1 = require("@pgtyped/runtime");
var getClientIR = { "usedParamSet": { "clientId": true, "clientSecret": true }, "params": [{ "name": "clientId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 83, "b": 92 }] }, { "name": "clientSecret", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 114, "b": 127 }] }], "statement": "SELECT client_id, client_secret, redirect_uri FROM oauth_clients WHERE client_id = :clientId! AND client_secret = :clientSecret!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT client_id, client_secret, redirect_uri FROM oauth_clients WHERE client_id = :clientId! AND client_secret = :clientSecret!
 * ```
 */
exports.getClient = new runtime_1.PreparedQuery(getClientIR);
var getRefreshTokenIR = { "usedParamSet": { "refreshToken": true }, "params": [{ "name": "refreshToken", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 107, "b": 120 }] }], "statement": "SELECT client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE refresh_token = :refreshToken!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE refresh_token = :refreshToken!
 * ```
 */
exports.getRefreshToken = new runtime_1.PreparedQuery(getRefreshTokenIR);
var saveRefreshTokenIR = { "usedParamSet": { "clientId": true, "refreshToken": true, "refreshTokenExpiresOn": true, "userId": true }, "params": [{ "name": "clientId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 94, "b": 103 }] }, { "name": "refreshToken", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 106, "b": 119 }] }, { "name": "refreshTokenExpiresOn", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 122, "b": 144 }] }, { "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 147, "b": 154 }] }], "statement": "INSERT INTO oauth_tokens(client_id, refresh_token, refresh_token_expires_on, user_id) VALUES (:clientId!, :refreshToken!, :refreshTokenExpiresOn!, :userId!)" };
/**
 * Query generated from SQL:
 * ```
 * INSERT INTO oauth_tokens(client_id, refresh_token, refresh_token_expires_on, user_id) VALUES (:clientId!, :refreshToken!, :refreshTokenExpiresOn!, :userId!)
 * ```
 */
exports.saveRefreshToken = new runtime_1.PreparedQuery(saveRefreshTokenIR);
var deleteRefreshTokenIR = { "usedParamSet": { "refreshToken": true }, "params": [{ "name": "refreshToken", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 47, "b": 60 }] }], "statement": "DELETE FROM oauth_tokens WHERE refresh_token = :refreshToken!" };
/**
 * Query generated from SQL:
 * ```
 * DELETE FROM oauth_tokens WHERE refresh_token = :refreshToken!
 * ```
 */
exports.deleteRefreshToken = new runtime_1.PreparedQuery(deleteRefreshTokenIR);
