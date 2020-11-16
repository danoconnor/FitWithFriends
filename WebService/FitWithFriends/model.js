
/**
 * Module dependencies.
 */

const pgp = require('pg-promise')()

// Database connection details;
const cn = {
    host: process.env.PGHOST,
    port: process.env.PGPORT,
    database: process.env.PGDATABASE,
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
};

const pg = pgp(cn)

pg.query('SELECT * FROM users')
    .then(function (result) {
        console.log(result)
    });

//pg.query('SELECT client_id, client_secret, redirect_uri FROM oauth_clients WHERE client_id = $1', ['5e464d5d-5d2d-46af-a834-e36a49c4b805'])
//    .then(function (result) {
//        var oAuthClient = result.rows[0];

//        if (!oAuthClient) {
//            return;
//        }
//    });

/*
 *  Authroization codes
 */

module.exports.saveAuthorizationCode = function (token, client, user) {
    pg.query('INSERT INTO oauth_tokens(access_token, access_token_expires_on, client_id, refresh_token, refresh_token_expires_on, user_id) VALUES ($1, $2, $3, $4)', [
        token.accessToken,
        token.accessTokenExpiresOn,
        client.id,
        token.refreshToken,
        token.refreshTokenExpiresOn,
        user.id
    ]).then(function (result) {
        return result.rowCount ? result.rows[0] : false; // TODO return object with client: {id: clientId} and user: {id: userId} defined
    });
};

/*
 * Get access token.
 */

module.exports.getAccessToken = function (bearerToken) {
    return pg.query('SELECT access_token, access_token_expires_on, client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE access_token = $1', [bearerToken])
        .then(function (result) {
            var token = result.rows[0];

            return {
                accessToken: token.access_token,
                client: { id: token.client_id },
                expires: token.expires,
                user: { id: token.userId }, // could be any object
            };
        });
};

/**
 * Get client.
 */

module.exports.getClient = function (clientId, clientSecret) {
    return pg.query('SELECT client_id, client_secret, redirect_uri FROM oauth_clients WHERE client_id = $1', [clientId])
        .then(function (result) {
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
    return pg.query('SELECT access_token, access_token_expires_on, client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE refresh_token = $1', [bearerToken])
        .then(function (result) {
            return result.rowCount ? result.rows[0] : false;
        });
};

/*
 * Get user.
 */

module.exports.getUser = function (username, password) {
    return pg.query('SELECT id FROM users WHERE username = $1 AND password = $2', [username, password])
        .then(function (result) {
            return result.rowCount ? result.rows[0] : false;
        });
};

/**
 * Save token.
 */

module.exports.saveAccessToken = function (token, client, user) {
    return pg.query('INSERT INTO oauth_tokens(access_token, access_token_expires_on, client_id, refresh_token, refresh_token_expires_on, user_id) VALUES ($1, $2, $3, $4)', [
        token.accessToken,
        token.accessTokenExpiresOn,
        client.id,
        token.refreshToken,
        token.refreshTokenExpiresOn,
        user.id
    ]).then(function (result) {
        return result.rowCount ? result.rows[0] : false; // TODO return object with client: {id: clientId} and user: {id: userId} defined
    });
};