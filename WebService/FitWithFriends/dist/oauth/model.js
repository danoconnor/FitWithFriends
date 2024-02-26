"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const identity_1 = require("@azure/identity");
const keyvault_keys_1 = require("@azure/keyvault-keys");
const keyvault_secrets_1 = require("@azure/keyvault-secrets");
const cryptoHelpers = require("../utilities/cryptoHelpers");
const jwt = require("jsonwebtoken");
const util = require("util");
const OauthQueries = __importStar(require("../sql/oauth.queries"));
const database_1 = require("../utilities/database");
const userHelpers_1 = require("../utilities/userHelpers");
class AuthenticationModel {
    accessTokenPublicKeyPem;
    tokenIssuer = 'com.danoconnor.fitwithfriends';
    // The default grant types that we support
    // Note that the apple_id_token grant type is a custom type we have defined (AppleIdTokenGrant.ts)
    // that allows us to issue refresh tokens if we are provided a valid Sign-In With Apple id token
    defaultGrants = ['apple_id_token', 'refresh_token'];
    constructor() {
        this.accessTokenPublicKeyPem = '';
        // This will run async and set the accessTokenPublicKeyPem variable when it completes
        this.getPublicKeyFromAzureKeyvault();
    }
    // Finds the refresh token in the database that matches the token that the client provided
    getRefreshToken(refreshToken) {
        return OauthQueries.getRefreshToken.run({ refreshToken: refreshToken }, database_1.DatabaseConnectionPool)
            .then(result => {
            if (!result.length) {
                return false;
            }
            const tokenResult = result[0];
            const refreshToken = {
                refreshToken: tokenResult.refresh_token,
                refreshTokenExpiresAt: tokenResult.refresh_token_expires_on,
                client: { id: tokenResult.client_id, grants: this.defaultGrants },
                user: { id: (0, userHelpers_1.convertBufferToUserId)(tokenResult.user_id) }
            };
            return refreshToken;
        });
    }
    // Deletes the given refresh token from the database
    revokeToken(token) {
        return OauthQueries.deleteRefreshToken.run({ refreshToken: token.refreshToken }, database_1.DatabaseConnectionPool)
            .then(_result => {
            // Return true even if we didn't find the token in the database
            return true;
        });
    }
    // Creates a new refresh token. It will be saved to the database when the OAuth server calls saveRefreshToken
    generateRefreshToken(client, user, scope) {
        // Just create a random token string here. It is associated with the user when we actually write it to the database
        return Promise.resolve(cryptoHelpers.getRandomToken());
    }
    // Creates a new access token, valid for 1hr and signed by our Azure Keyvault private key
    generateAccessToken(client, user, scope) {
        // We manually create the access token, instead of using the jsonwebtoken library,
        // because we want to use Azure Keyvault to sign the token so that
        // the private key never leaves the vault
        const now = Math.floor(Date.now() / 1000);
        const payload = {
            iat: now,
            nbf: now,
            exp: now + (60 * 60), // Valid for 1hr
            sub: user.id,
            iss: this.tokenIssuer,
            aud: scope,
            client: client.id
        };
        const payloadBase64 = this.base64url(JSON.stringify(payload));
        const signingAlgorithm = 'RS256';
        const header = {
            alg: signingAlgorithm,
            typ: 'JWT',
            kid: process.env.ACCESS_TOKEN_SIGNING_KID_SHORT
        };
        const headerBase64 = this.base64url(JSON.stringify(header), 'binary');
        const dataToSign = util.format('%s.%s', headerBase64, payloadBase64);
        return this.signWithAzureKeyvault(dataToSign, signingAlgorithm)
            .then(result => {
            const signature = Buffer.from(result.result).toString('base64')
                .replace(/=/g, '')
                .replace(/\+/g, '-')
                .replace(/\//g, '_');
            return util.format('%s.%s.%s', headerBase64, payloadBase64, signature);
        });
    }
    // Looks up the client app in the database
    getClient(clientId, clientSecret) {
        return OauthQueries.getClient.run({ clientId: clientId, clientSecret: clientSecret }, database_1.DatabaseConnectionPool)
            .then(result => {
            if (!result.length) {
                return false;
            }
            const oAuthClient = result[0];
            return {
                id: oAuthClient.client_id,
                grants: this.defaultGrants,
            };
        });
    }
    saveToken(token, client, user) {
        // Our OAuth system reuses the same refresh token until it expires (or is otherwise revoked)
        // Since we only store the refresh token in the database, we don't need to do anything if the
        // refresh token hasn't changed
        if (!token.refreshToken) {
            const returnedAccessToken = {
                accessToken: token.accessToken,
                accessTokenExpiresAt: token.accessTokenExpiresAt,
                accessTokenExpiry: token.accessTokenExpiresAt,
                client: { id: client.id, grants: this.defaultGrants },
                user: user.id,
                userId: user.id,
                scope: token.scope
            };
            return Promise.resolve(returnedAccessToken);
        }
        return OauthQueries.saveRefreshToken.run({ clientId: token.client.id, refreshToken: token.refreshToken, refreshTokenExpiresOn: token.refreshTokenExpiresAt, userId: (0, userHelpers_1.convertUserIdToBuffer)(user.id) }, database_1.DatabaseConnectionPool)
            .then(_result => {
            const returnedRefreshToken = {
                accessToken: token.accessToken,
                refreshToken: token.refreshToken,
                refreshTokenExpiresAt: token.refreshTokenExpiresAt,
                client: { id: client.id, grants: this.defaultGrants },
                user: user.id,
                userId: user.id,
                scope: token.scope
            };
            return returnedRefreshToken;
        });
    }
    getAccessToken(accessToken) {
        // Make sure we've gotten the expected public key from the key vault
        if (!this.accessTokenPublicKeyPem.length) {
            throw new Error('Authentication system not initialized');
        }
        return new Promise((resolve, reject) => {
            const verificationOptions = {
                issuer: this.tokenIssuer
            };
            jwt.verify(accessToken, this.accessTokenPublicKeyPem, verificationOptions, function (error, decoded) {
                if (error) {
                    reject(error);
                    return;
                }
                // Expect the decoded payload to be a JwtPayload
                const decodedPayload = decoded;
                resolve({
                    accessToken: accessToken,
                    client: { id: decodedPayload.client, grants: ['apple_id_token', 'refresh_token'] },
                    accessTokenExpiresAt: new Date(decodedPayload.exp * 1000),
                    user: { id: decodedPayload.sub },
                    scope: decodedPayload.aud
                });
            });
        });
    }
    getPublicKeyFromAzureKeyvault() {
        // Used for testing - we can use a local keypair instead of the Azure Keyvault
        if (process.env.FWF_AUTH_USE_LOCAL_KEYPAIR === "1") {
            const fs = require('fs');
            const path = process.env.FWF_AUTH_PUBLIC_KEY_PATH;
            if (!path) {
                throw new Error('FWF_AUTH_PUBLIC_KEY_PATH environment variable not set');
            }
            this.accessTokenPublicKeyPem = fs.readFileSync(path, 'utf-8');
            return;
        }
        const publicKeySecretName = process.env.ACCESS_TOKEN_SIGNING_PUBLIC_KEY_NAME;
        const vaultUrl = process.env.AZURE_KEYVAULT_URL;
        const credential = new identity_1.DefaultAzureCredential();
        const client = new keyvault_secrets_1.SecretClient(vaultUrl, credential);
        // Don't catch errors on purpose - if this fails then we want the app to crash
        client.getSecret(publicKeySecretName)
            .then(result => {
            // The key vault stores the key with actual \n chars.
            // If we don't replace those with actual newlines, then we get key decoding errors
            this.accessTokenPublicKeyPem = result.value.replace(/\\n/g, '\n');
        });
    }
    base64url(string, encoding = 'utf-8') {
        return Buffer
            .from(string, encoding)
            .toString('base64')
            .replace(/=/g, '')
            .replace(/\+/g, '-')
            .replace(/\//g, '_');
    }
    signWithAzureKeyvault(dataToSign, signingAlgorithm) {
        // Used in testing - sign tokens with a local keypair
        if (process.env.FWF_AUTH_USE_LOCAL_KEYPAIR === "1") {
            const fs = require('fs');
            const path = process.env.FWF_AUTH_PRIVATE_KEY_PATH;
            if (!path) {
                throw new Error('FWF_AUTH_PRIVATE_KEY_PATH environment variable not set');
            }
            const privateKeyPem = fs.readFileSync(path, 'utf-8');
            const result = {
                result: cryptoHelpers.signData(dataToSign, privateKeyPem, 'RSA-SHA256'),
                algorithm: signingAlgorithm
            };
            return Promise.resolve(result);
        }
        const signingKeyId = process.env.ACCESS_TOKEN_SIGNING_KID;
        // Need to set AZURE_TENANT_ID, AZURE_CLIENT_ID, and AZURE_CLIENT_SECRET environment variables
        // for the credential to work
        const credential = new identity_1.DefaultAzureCredential();
        const cryptographyClient = new keyvault_keys_1.CryptographyClient(signingKeyId, credential);
        return cryptographyClient.signData(signingAlgorithm, Buffer.from(dataToSign));
    }
}
exports.default = AuthenticationModel;
