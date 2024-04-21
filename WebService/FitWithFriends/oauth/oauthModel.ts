import { DefaultAzureCredential } from '@azure/identity';
import { CryptographyClient, SignResult } from '@azure/keyvault-keys';
import { SecretClient } from '@azure/keyvault-secrets';
import cryptoHelpers = require('../utilities/cryptoHelpers');
import jwt = require('jsonwebtoken');
import util = require('util');
import { RequestAuthenticationModel, RefreshTokenModel, ExtensionModel, Client, Falsey, Token, User, RefreshToken, UnauthorizedRequestError } from '@node-oauth/oauth2-server';
import * as OauthQueries from '../sql/oauth.queries';
import { convertBufferToUserId, convertUserIdToBuffer } from '../utilities/userHelpers';

class AuthenticationModel implements RequestAuthenticationModel, RefreshTokenModel, ExtensionModel {
    private accessTokenPublicKeyPem: string;
    private tokenIssuer = 'com.danoconnor.fitwithfriends';

    // The default grant types that we support
    // Note that the apple_id_token grant type is a custom type we have defined (AppleIdTokenGrant.ts)
    // that allows us to issue refresh tokens if we are provided a valid Sign-In With Apple id token
    private defaultGrants = ['apple_id_token', 'refresh_token'];

    constructor() {
        this.accessTokenPublicKeyPem = '';

        // This will run async and set the accessTokenPublicKeyPem variable when it completes
        this.getPublicKeyFromAzureKeyvault();
    }

    // Finds the refresh token in the database that matches the token that the client provided
    getRefreshToken(refreshToken: string): Promise<Falsey | RefreshToken> {
        return OauthQueries.getRefreshToken({refreshToken: refreshToken})
            .then(result => {
                if (!result.length) {
                    return false;
                }

                const tokenResult = result[0];
                const refreshToken: RefreshToken = {
                    refreshToken: tokenResult.refresh_token,
                    refreshTokenExpiresAt: tokenResult.refresh_token_expires_on,
                    client: { id: tokenResult.client_id, grants: this.defaultGrants },
                    user: { id: convertBufferToUserId(tokenResult.user_id) }
                };

                return refreshToken;
            });
    }

    // Deletes the given refresh token from the database
    revokeToken(token: RefreshToken): Promise<boolean> {
        return OauthQueries.deleteRefreshToken({refreshToken: token.refreshToken})
            .then(_result => {
                // Return true even if we didn't find the token in the database
                return true;
            });
    }

    // Creates a new refresh token. It will be saved to the database when the OAuth server calls saveRefreshToken
    generateRefreshToken(client: Client, user: User, scope: string[]): Promise<string> {
        // Just create a random token string here. It is associated with the user when we actually write it to the database
        return Promise.resolve(cryptoHelpers.getRandomToken());
    }

    // Creates a new access token, valid for 1hr and signed by our Azure Keyvault private key
    generateAccessToken(client: Client, user: User, scope: string[]): Promise<string> {
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
        }
        const payloadBase64 = this.base64url(JSON.stringify(payload));

        const signingAlgorithm = 'RS256';
        const header = {
            alg: signingAlgorithm,
            typ: 'JWT',
            kid: process.env.ACCESS_TOKEN_SIGNING_KID_SHORT
        }
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
    getClient(clientId: string, clientSecret: string): Promise<Client | Falsey> {
        return OauthQueries.getClient({clientId: clientId, clientSecret: clientSecret})
            .then(result => {
                if (!result.length) {
                    return false;
                }

                const oAuthClient = result[0];
                return {
                    id: oAuthClient.client_id,
                    grants: this.defaultGrants,
                };
            })
            .catch(error => {
                console.error('Error getting client: ', error);
                throw error;
            });
    }

    saveToken(token: Token, client: Client, user: User): Promise<Token | Falsey> {
        // Our OAuth system reuses the same refresh token until it expires (or is otherwise revoked)
        // Since we only store the refresh token in the database, we don't need to do anything if the
        // refresh token hasn't changed
        if (!token.refreshToken) {
            const returnedAccessToken: Token = {
                accessToken: token.accessToken,
                accessTokenExpiresAt: token.accessTokenExpiresAt,
                client: { id: client.id, grants: this.defaultGrants }, 
                user: user.id,
                scope: token.scope,
                // By default, the OAuth server will not return these properties
                // We have enabled the allowExtendedTokenAttributes option to enable us to add properties
                userId: user.id,
                // Include the AT expiry date again here since the OAuth server doesn't return the built in accessTokenExpiresAt property
                accessTokenExpiry: token.accessTokenExpiresAt,
            };
            return Promise.resolve(returnedAccessToken);
        }

        return OauthQueries.saveRefreshToken({ clientId: token.client.id, refreshToken: token.refreshToken, refreshTokenExpiresOn: token.refreshTokenExpiresAt, userId: convertUserIdToBuffer(user.id) })
            .then(_result => {
               const returnedRefreshToken: Token = {
                    accessToken: token.accessToken,
                    accessTokenExpiresAt: token.accessTokenExpiresAt,
                    refreshToken: token.refreshToken,
                    refreshTokenExpiresAt: token.refreshTokenExpiresAt,
                    client: { id: client.id, grants: this.defaultGrants }, 
                    user: user.id,
                    scope: token.scope,
                    // By default, the OAuth server will not return these properties
                    // We have enabled the allowExtendedTokenAttributes option to enable us to add properties
                    userId: user.id,
                    // Include the AT expiry date again here since the OAuth server doesn't return the built in accessTokenExpiresAt property
                    accessTokenExpiry: token.accessTokenExpiresAt,
               };
               return returnedRefreshToken;
            });
    }

    getAccessToken(accessToken: string): Promise<Token | Falsey> {
        // Make sure we've gotten the expected public key from the key vault
        if (!this.accessTokenPublicKeyPem.length) {
            throw new Error('Authentication system not initialized');
        }

        return new Promise((resolve, reject) => {
            const verificationOptions: jwt.VerifyOptions = {
                issuer: this.tokenIssuer
            }

            jwt.verify(accessToken, this.accessTokenPublicKeyPem, verificationOptions, function (error, decoded) {
                if (error) {
                    reject(new UnauthorizedRequestError(error.message));
                    return;
                }

                // Expect the decoded payload to be a JwtPayload
                const decodedPayload = decoded as jwt.JwtPayload;

                resolve({
                    accessToken: accessToken,
                    client: { id: decodedPayload.client, grants: ['apple_id_token', 'refresh_token']},
                    accessTokenExpiresAt: new Date(decodedPayload.exp * 1000),
                    user: { id: decodedPayload.sub },
                    scope: decodedPayload.aud as string[]
                });
            });
        });
    }

    private getPublicKeyFromAzureKeyvault() {
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
    
        const credential = new DefaultAzureCredential();
        const client = new SecretClient(vaultUrl, credential);
    
        // Don't catch errors on purpose - if this fails then we want the app to crash
        client.getSecret(publicKeySecretName)
            .then(result => {
                // The key vault stores the key with actual \n chars.
                // If we don't replace those with actual newlines, then we get key decoding errors
                this.accessTokenPublicKeyPem = result.value.replace(/\\n/g, '\n');
            })
    }

    private base64url(string: string, encoding: BufferEncoding = 'utf-8'): string {
        return Buffer
            .from(string, encoding)
            .toString('base64')
            .replace(/=/g, '')
            .replace(/\+/g, '-')
            .replace(/\//g, '_');
    }

    private signWithAzureKeyvault(dataToSign, signingAlgorithm): Promise<SignResult> {
        // Used in testing - sign tokens with a local keypair
        if (process.env.FWF_AUTH_USE_LOCAL_KEYPAIR === "1") {
            const fs = require('fs');
            const path = process.env.FWF_AUTH_PRIVATE_KEY_PATH;
            if (!path) {
                throw new Error('FWF_AUTH_PRIVATE_KEY_PATH environment variable not set');
            }

            const privateKeyPem = fs.readFileSync(path, 'utf-8');
            const result: SignResult = {
                result: cryptoHelpers.signData(dataToSign, privateKeyPem, 'RSA-SHA256'),
                algorithm: signingAlgorithm
            };
            return Promise.resolve(result);
        }

        const signingKeyId = process.env.ACCESS_TOKEN_SIGNING_KID;
    
        // Need to set AZURE_TENANT_ID, AZURE_CLIENT_ID, and AZURE_CLIENT_SECRET environment variables
        // for the credential to work
        const credential = new DefaultAzureCredential();
        const cryptographyClient = new CryptographyClient(signingKeyId, credential);
    
        return cryptographyClient.signData(signingAlgorithm, Buffer.from(dataToSign));
    }
}

export default AuthenticationModel;