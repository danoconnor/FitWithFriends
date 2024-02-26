"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateAppleIdToken = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const jwks_rsa_1 = __importDefault(require("jwks-rsa"));
const appleJwks = (0, jwks_rsa_1.default)({
    jwksUri: 'https://appleid.apple.com/auth/keys'
});
// Based on https://github.com/auth0/node-jsonwebtoken#usage
function getApplePublicKey(header, callback) {
    appleJwks.getSigningKey(header.kid, function (err, key) {
        if (err) {
            callback(err);
            return;
        }
        const signingKey = key?.getPublicKey();
        callback(null, signingKey);
    });
}
// Checks that the given id token is valid and issued by Apple
// Returns a Promise that will return a bool indicating if the token is valid
function validateAppleIdToken(userId, idToken) {
    // If we are testing locally, skip the token validation
    if (process.env.FWF_AUTH_USE_LOCAL_KEYPAIR === '1') {
        console.log('Local testing override: Apple ID token validation skipped');
        return Promise.resolve(true);
    }
    return new Promise((resolve, reject) => {
        // We need to verify four things about the ID token (from: https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/verifying_a_user)
        // Verify the JWS E256 signature using the server�s public key
        // Verify that the iss field contains https://appleid.apple.com
        // Verify that the aud field is the developer's client_id
        // Verify that the time is earlier than the exp value of the token
        // The JWT library will ensure that the token matches these given values
        const verificationOptions = {
            audience: 'com.danoconnor.FitWithFriends',
            issuer: 'https://appleid.apple.com',
            subject: userId
        };
        jsonwebtoken_1.default.verify(idToken, getApplePublicKey, verificationOptions, function (error, decoded) {
            if (error) {
                reject(error);
            }
            else {
                // Return false if the token couldn't be decoded for some reason
                resolve(decoded != null);
            }
        });
    });
}
exports.validateAppleIdToken = validateAppleIdToken;
;
