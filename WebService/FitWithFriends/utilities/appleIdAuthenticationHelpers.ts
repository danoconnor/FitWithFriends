import jwt, { JwtHeader, SigningKeyCallback } from 'jsonwebtoken';
import jwks from 'jwks-rsa';

const appleJwks = jwks({
    jwksUri: 'https://appleid.apple.com/auth/keys'
})

// Based on https://github.com/auth0/node-jsonwebtoken#usage
function getApplePublicKey(header: JwtHeader, callback: SigningKeyCallback) {
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
function validateAppleIdToken(userId: string, idToken: string) {
    return new Promise<boolean>((resolve, reject) => {
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

export { validateAppleIdToken }