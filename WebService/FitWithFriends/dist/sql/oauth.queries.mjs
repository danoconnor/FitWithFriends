/** Types generated for queries found in "sql/oauth.sql" */
import { PreparedQuery } from '@pgtyped/runtime';
const getClientIR = { "usedParamSet": { "clientId": true, "clientSecret": true }, "params": [{ "name": "clientId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 83, "b": 92 }] }, { "name": "clientSecret", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 114, "b": 127 }] }], "statement": "SELECT client_id, client_secret, redirect_uri FROM oauth_clients WHERE client_id = :clientId! AND client_secret = :clientSecret!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT client_id, client_secret, redirect_uri FROM oauth_clients WHERE client_id = :clientId! AND client_secret = :clientSecret!
 * ```
 */
export const getClient = new PreparedQuery(getClientIR);
const getRefreshTokenIR = { "usedParamSet": { "refreshToken": true }, "params": [{ "name": "refreshToken", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 107, "b": 120 }] }], "statement": "SELECT client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE refresh_token = :refreshToken!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE refresh_token = :refreshToken!
 * ```
 */
export const getRefreshToken = new PreparedQuery(getRefreshTokenIR);
const saveRefreshTokenIR = { "usedParamSet": { "clientId": true, "refreshToken": true, "refreshTokenExpiresOn": true, "userId": true }, "params": [{ "name": "clientId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 94, "b": 103 }] }, { "name": "refreshToken", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 106, "b": 119 }] }, { "name": "refreshTokenExpiresOn", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 122, "b": 144 }] }, { "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 147, "b": 154 }] }], "statement": "INSERT INTO oauth_tokens(client_id, refresh_token, refresh_token_expires_on, user_id) VALUES (:clientId!, :refreshToken!, :refreshTokenExpiresOn!, :userId!)" };
/**
 * Query generated from SQL:
 * ```
 * INSERT INTO oauth_tokens(client_id, refresh_token, refresh_token_expires_on, user_id) VALUES (:clientId!, :refreshToken!, :refreshTokenExpiresOn!, :userId!)
 * ```
 */
export const saveRefreshToken = new PreparedQuery(saveRefreshTokenIR);
const deleteRefreshTokenIR = { "usedParamSet": { "refreshToken": true }, "params": [{ "name": "refreshToken", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 47, "b": 60 }] }], "statement": "DELETE FROM oauth_tokens WHERE refresh_token = :refreshToken!" };
/**
 * Query generated from SQL:
 * ```
 * DELETE FROM oauth_tokens WHERE refresh_token = :refreshToken!
 * ```
 */
export const deleteRefreshToken = new PreparedQuery(deleteRefreshTokenIR);
