const jwt = require('jsonwebtoken');
const jwks = require('jwks-rsa');

const appleJwks = jwks({
    jwksUri: 'https://appleid.apple.com/auth/keys'
})

// Checks that the given id token is valid and issued by Apple
// Returns a Promise that will return a bool indicating if the token is valid
module.exports.validateIdToken = function (userId, idToken) {
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
        jwt.verify(idToken, getApplePublicKey, verificationOptions, function (error, decoded) {
            if (error) {
                reject(error);
            } else {
                // Return false if the token couldn't be decoded for some reason
                resolve(decoded != null);
            }
        });
    });
};

// From https://github.com/auth0/node-jsonwebtoken#usage
function getApplePublicKey(header, callback) {
    appleJwks.getSigningKey(header.kid, function (err, key) {
        var signingKey = key.publicKey || key.rsaPublicKey;
        callback(null, signingKey);
    });
}