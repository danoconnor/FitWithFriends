import crypto from 'crypto';
import jwt from 'jsonwebtoken';

/*
    Unit tests for validateAppleIdToken.

    The integration tests run with FWF_AUTH_USE_LOCAL_KEYPAIR=1, which skips Apple token validation
    entirely. These tests exercise the real validation logic (signature, iss, aud, sub, exp) by
    replacing only the JWKS client with one that serves a locally generated key set in place of
    Apple's keys. The production jwks-rsa client is covered separately (see the PR description).
*/

const KID = 'testkid1';
const AUDIENCE = 'com.danoconnor.FitWithFriends';
const ISSUER = 'https://appleid.apple.com';
const USER_ID = 'user-123';

const mockTrustedKeys = crypto.generateKeyPairSync('rsa', { modulusLength: 2048 });
const mockRogueKeys = crypto.generateKeyPairSync('rsa', { modulusLength: 2048 });
const mockPublicKeysByKid: Record<string, crypto.KeyObject> = { [KID]: mockTrustedKeys.publicKey };

// jest.mock is hoisted, but the factory only runs when the helper module is first required
// (inside each test), by which point the key fixtures above exist.
jest.mock('jwks-rsa', () => ({
    __esModule: true,
    default: () => ({
        getSigningKey: (kid: string | null | undefined, callback: (err: Error | null, key?: unknown) => void) => {
            const publicKey = kid ? mockPublicKeysByKid[kid] : undefined;
            if (!publicKey) {
                callback(new Error(`Unable to find a signing key that matches '${kid}'`));
                return;
            }
            callback(null, { getPublicKey: () => publicKey.export({ type: 'spki', format: 'pem' }).toString() });
        },
    }),
}));

function mintToken(privateKey: crypto.KeyObject, kid: string, claims: Record<string, unknown> = {}) {
    const payload = { iss: ISSUER, aud: AUDIENCE, sub: USER_ID, ...claims };
    const options: jwt.SignOptions = { algorithm: 'RS256', keyid: kid };
    if (claims.exp === undefined) {
        options.expiresIn = 300;
    }
    return jwt.sign(payload, privateKey, options);
}

describe('validateAppleIdToken', () => {
    const originalLocalKeypairFlag = process.env.FWF_AUTH_USE_LOCAL_KEYPAIR;

    beforeEach(() => {
        // Exercise real validation, not the local-testing bypass.
        process.env.FWF_AUTH_USE_LOCAL_KEYPAIR = '0';
    });

    afterAll(() => {
        if (originalLocalKeypairFlag === undefined) {
            delete process.env.FWF_AUTH_USE_LOCAL_KEYPAIR;
        } else {
            process.env.FWF_AUTH_USE_LOCAL_KEYPAIR = originalLocalKeypairFlag;
        }
    });

    const validate = (token: string) =>
        // Required lazily so the jest.mock above is in effect when the helper builds its JWKS client.
        (require('../../utilities/appleIdAuthenticationHelpers') as typeof import('../../utilities/appleIdAuthenticationHelpers'))
            .validateAppleIdToken(USER_ID, token);

    it('accepts a token signed by the Apple key with matching iss, aud and sub', async () => {
        await expect(validate(mintToken(mockTrustedKeys.privateKey, KID))).resolves.toBe(true);
    });

    it('rejects a token whose subject does not match the user', async () => {
        await expect(validate(mintToken(mockTrustedKeys.privateKey, KID, { sub: 'someone-else' })))
            .rejects.toThrow(jwt.JsonWebTokenError);
    });

    it('rejects a token with the wrong audience', async () => {
        await expect(validate(mintToken(mockTrustedKeys.privateKey, KID, { aud: 'com.evil.app' })))
            .rejects.toThrow(jwt.JsonWebTokenError);
    });

    it('rejects a token with the wrong issuer', async () => {
        await expect(validate(mintToken(mockTrustedKeys.privateKey, KID, { iss: 'https://evil.example' })))
            .rejects.toThrow(jwt.JsonWebTokenError);
    });

    it('rejects a token whose kid is not in the Apple key set', async () => {
        await expect(validate(mintToken(mockTrustedKeys.privateKey, 'no-such-kid'))).rejects.toThrow();
    });

    it('rejects a token signed by a different key even when it claims a trusted kid', async () => {
        await expect(validate(mintToken(mockRogueKeys.privateKey, KID))).rejects.toThrow(jwt.JsonWebTokenError);
    });

    it('rejects an expired token', async () => {
        const expired = mintToken(mockTrustedKeys.privateKey, KID, { exp: Math.floor(Date.now() / 1000) - 60 });
        await expect(validate(expired)).rejects.toThrow(jwt.TokenExpiredError);
    });
});
