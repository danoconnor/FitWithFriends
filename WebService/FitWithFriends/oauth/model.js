
/**
 * Module dependencies.
 */

const cryptoHelpers = require('../utilities/cryptoHelpers')
const database = require('../utilities/database')

/*
 *  Authroization codes
 */

module.exports.saveAuthorizationCode = function (token, client, user) {
    database.query('INSERT INTO oauth_tokens(access_token, access_token_expires_on, client_id, refresh_token, refresh_token_expires_on, user_id) VALUES ($1, $2, $3, $4)', [
        token.accessToken,
        token.accessTokenExpiresOn,
        client.id,
        token.refreshToken,
        token.refreshTokenExpiresOn,
        user.id
    ]).then(function (result) {
        return result.length ? result[0] : false; // TODO return object with client: {id: clientId} and user: {id: userId} defined
    });
};

/*
 * Get access token.
 */

module.exports.getAccessToken = function (bearerToken) {
    return database.query('SELECT access_token, access_token_expires_on, client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE access_token = $1', [bearerToken])
        .then(function (result) {
            if (!result.length) { return false }
            var token = result[0];

            return {
                accessToken: token.access_token,
                client: { id: token.client_id },
                accessTokenExpiresAt: token.access_token_expires_on,
                user: { id: token.user_id }
            };
        });
};

/**
 * Get client.
 */

module.exports.getClient = function (clientId, clientSecret) {
    return database.query('SELECT client_id, client_secret, redirect_uri FROM oauth_clients WHERE client_id = $1', [clientId])
        .then(function (result) {
            if (!result.length) { return false }
            var oAuthClient = result[0];

            if (!oAuthClient) {
                return;
            }

            return {
                clientId: oAuthClient.client_id,
                clientSecret: oAuthClient.client_secret,
                grants: ['password', 'authorization_code'], // the list of OAuth2 grant types that should be allowed
            };
        });
};

/**
 * Get refresh token.
 */

module.exports.getRefreshToken = function (bearerToken) {
    return database.query('SELECT access_token, access_token_expires_on, client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE refresh_token = $1', [bearerToken])
        .then(function (result) {
            return result.length ? result[0] : false;
        });
};

/*
 * Get user.
 */

module.exports.getUser = function (username, password) {
    // Lookup user by username so we can get the salt, then check that password hash matches
    return database.query('SELECT * FROM users WHERE username = $1', [username])
        .then(function (result) {
            const user = result.length ? result[0] : false;
            if (!user) {
                // Username was not found
                return false
            }

            const salt = user.password_salt
            const expectedPasswordHash = cryptoHelpers.getHash(password, salt)
            if (expectedPasswordHash === user.password_hash) {
                return user
            } else {
                // Password did not match
                return false
            }
        });
};

/**
 * Save token.
 */

module.exports.saveToken = function (token, client, user) {
    return database.query('INSERT INTO oauth_tokens(access_token, access_token_expires_on, client_id, refresh_token, refresh_token_expires_on, user_id) VALUES ($1, $2, $3, $4, $5, $6)', [
        token.accessToken,
        token.accessTokenExpiresAt,
        client.clientId,
        token.refreshToken,
        token.refreshTokenExpiresAt,
        user.userid
    ]).then(function (result) {
        // TODO return object with client: {id: clientId} and user: {id: userId} defined
        return {
            accessToken: token.accessToken,
            accessTokenExpiresAt: token.accessTokenExpiresAt,
            refreshToken: token.refreshToken,
            refreshTokenExpiresAt: token.refreshTokenExpiresAt,
            scope: token.scope,
            client: client,
            user: user
        }
    }).catch(function (error) {
        // TODO: log error
        return false
    });
};