var DefaultAzureCredential = require('@azure/identity').DefaultAzureCredential;
var CryptographyClient = require('@azure/keyvault-keys').CryptographyClient;
var SecretClient = require('@azure/keyvault-secrets').SecretClient;
var cryptoHelpers = require('../utilities/cryptoHelpers');
var database = require('../utilities/database');
var jwt = require('jsonwebtoken');
var util = require('util');
var tokenIssuer = 'com.danoconnor.fitwithfriends';
var accessTokenPublicKeyPem;
getPublicKeyFromAzureKeyvault();
/*
 *  Authroization codes
 */
module.exports.saveAuthorizationCode = function (token, client, user) {
    // Prefix the value with \x so the database will treat it as a hex value
    var sqlHexUserId = '\\x' + user.id;
    database.query('INSERT INTO oauth_tokens(client_id, refresh_token, refresh_token_expires_on, user_id) VALUES ($1, $2, $3, $4)', [
        client.id,
        token.refreshToken,
        token.refreshTokenExpiresOn,
        sqlHexUserId
    ]).then(function (result) {
        return result.length ? result[0] : false; // TODO return object with client: {id: clientId} and user: {id: userId} defined
    });
};
/*
 * Get access token.
 */
module.exports.getAccessToken = function (bearerToken) {
    // Make sure we've gotten the expected public key from the key vault
    if (!accessTokenPublicKeyPem) {
        return null;
    }
    return new Promise(function (resolve, reject) {
        var verificationOptions = {
            iss: tokenIssuer
        };
        jwt.verify(bearerToken, accessTokenPublicKeyPem, verificationOptions, function (error, decoded) {
            if (error) {
                reject(error);
            }
            resolve({
                accessToken: bearerToken,
                client: { id: decoded.client },
                accessTokenExpiresAt: new Date(decoded.exp * 1000),
                user: { id: decoded.sub },
                scope: decoded.aud
            });
        });
    });
};
/**
 * Get client.
 */
module.exports.getClient = function (clientId, clientSecret) {
    return database.query('SELECT client_id, client_secret, redirect_uri FROM oauth_clients WHERE client_id = $1 AND client_secret = $2', [clientId, clientSecret])
        .then(function (result) {
        if (!result.length) {
            return false;
        }
        var oAuthClient = result[0];
        if (!oAuthClient) {
            return;
        }
        return {
            id: oAuthClient.client_id,
            grants: ['apple_id_token', 'refresh_token'], // the list of grant types that should be allowed. Note: apple_id_token is a unique grant type that we have defined
        };
    });
};
/**
 * Get refresh token.
 */
module.exports.getRefreshToken = function (bearerToken) {
    return database.query('SELECT client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE refresh_token = $1', [bearerToken])
        .then(function (result) {
        if (!result.length) {
            return false;
        }
        var token = result[0];
        return {
            refreshToken: token.refresh_token,
            refreshTokenExpiresAt: token.refresh_token_expires_on,
            client: { id: token.client_id },
            user: { id: Buffer.from(token.user_id).toString('hex') }
        };
    });
};
/**
 * Save token.
 */
module.exports.saveToken = function (token, client, user) {
    // Our OAuth system reuses the same refresh token until it expires (or is otherwise revoked)
    // Since we only store the refresh token in the database, we don't need to do anything if the
    // refresh token hasn't changed
    if (!token.refreshToken) {
        return {
            accessToken: token.accessToken,
            accessTokenExpiresAt: token.accessTokenExpiresAt,
            accessTokenExpiry: token.accessTokenExpiresAt,
            client: client.id,
            user: user.id,
            userId: user.id,
            scope: token.scope
        };
    }
    // Prefix the value with \x so the database will treat it as a hex value
    var sqlHexUserId = '\\x' + user.id;
    return database.query('INSERT INTO oauth_tokens(client_id, refresh_token, refresh_token_expires_on, user_id) VALUES ($1, $2, $3, $4)', [
        client.id,
        token.refreshToken,
        token.refreshTokenExpiresAt,
        sqlHexUserId
    ]).then(function (result) {
        return {
            accessToken: token.accessToken,
            accessTokenExpiresAt: token.accessTokenExpiresAt,
            refreshToken: token.refreshToken,
            refreshTokenExpiresAt: token.refreshTokenExpiresAt,
            scope: token.scope,
            client: client.id,
            user: user.id,
            userId: user.id,
            accessTokenExpiry: token.accessTokenExpiresAt,
            refreshTokenExpiry: token.refreshTokenExpiresAt,
        };
    });
};
/**
 * Revoke token.
 */
module.exports.revokeToken = function (token) {
    return database.query('DELETE FROM oauth_tokens WHERE refresh_token = $1', [
        token.refreshToken
    ]).then(function (result) {
        return true;
    }).catch(function (error) {
        return false;
    });
};
/**
 * Generate access token.
 */
module.exports.generateAccessToken = function (client, user, scope) {
    // We manually create the access token, instead of using the jsonwebtoken library,
    // because we want to use Azure Keyvault to sign the token so that
    // the private key never leaves the vault
    var now = Math.floor(Date.now() / 1000);
    var payload = {
        iat: now,
        nbf: now,
        exp: now + (60 * 60), // Valid for 1hr
        sub: user.id,
        iss: tokenIssuer,
        aud: scope,
        client: client.id
    };
    var payloadBase64 = base64url(JSON.stringify(payload));
    var signingAlgorithm = 'RS256';
    var header = {
        alg: signingAlgorithm,
        typ: 'JWT',
        kid: process.env.ACCESS_TOKEN_SIGNING_KID_SHORT
    };
    var headerBase64 = base64url(JSON.stringify(header), 'binary');
    var dataToSign = util.format('%s.%s', headerBase64, payloadBase64);
    return signWithAzureKeyvault(dataToSign, signingAlgorithm)
        .then(function (result) {
        var signature = Buffer.from(result.result).toString('base64')
            .replace(/=/g, '')
            .replace(/\+/g, '-')
            .replace(/\//g, '_');
        return util.format('%s.%s.%s', headerBase64, payloadBase64, signature);
    });
};
/**
 * Generate refresh token.
 */
module.exports.generateRefreshToken = function (client, user, scope) {
    // Just create a random token string here. It is associated with the user when we actually write it to the database
    return cryptoHelpers.getRandomToken();
};
// Helper functions
// Returns a promise that will return the signature
function signWithAzureKeyvault(dataToSign, signingAlgorithm) {
    var signingKeyId = process.env.ACCESS_TOKEN_SIGNING_KID;
    // Need to set AZURE_TENANT_ID, AZURE_CLIENT_ID, and AZURE_CLIENT_SECRET environment variables
    // for the credential to work
    var credential = new DefaultAzureCredential();
    var cryptographyClient = new CryptographyClient(signingKeyId, credential);
    return cryptographyClient.signData(signingAlgorithm, Buffer.from(dataToSign));
}
function getPublicKeyFromAzureKeyvault() {
    var publicKeySecretName = process.env.ACCESS_TOKEN_SIGNING_PUBLIC_KEY_NAME;
    var vaultUrl = process.env.AZURE_KEYVAULT_URL;
    var credential = new DefaultAzureCredential();
    var client = new SecretClient(vaultUrl, credential);
    client.getSecret(publicKeySecretName)
        .then(function (result) {
        // The key vault stores the key with actual \n chars.
        // If we don't replace those with actual newlines, then we get key decoding errors
        accessTokenPublicKeyPem = result.value.replace(/\\n/g, '\n');
    })
        .catch(function (error) {
        console.error(error.message);
    });
}
function base64url(string, encoding) {
    return Buffer
        .from(string, encoding || 'utf8')
        .toString('base64')
        .replace(/=/g, '')
        .replace(/\+/g, '-')
        .replace(/\//g, '_');
}
