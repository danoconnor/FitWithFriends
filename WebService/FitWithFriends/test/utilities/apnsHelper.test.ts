import { EventEmitter } from 'events';

/*
    Unit tests for apnsHelper.
    These exercise the real (non-test-environment) code paths by resetting the module
    between tests and mocking the http2 / Azure / SQL dependencies.
*/

// --- helpers ---

function makeMockStream(statusCode: number, body: string) {
    const emitter = new EventEmitter();
    return {
        on: (event: string, handler: (...args: unknown[]) => void) => { emitter.on(event, handler); return emitter; },
        write: jest.fn(),
        end: jest.fn().mockImplementation(() => {
            setImmediate(() => {
                emitter.emit('response', { ':status': statusCode });
                emitter.emit('data', Buffer.from(body));
                emitter.emit('end');
            });
        }),
    };
}

function makeMockSession(responses: Array<{ statusCode: number; body: string }>) {
    let call = 0;
    const sessionEmitter = new EventEmitter();
    return {
        destroyed: false,
        closed: false,
        request: jest.fn().mockImplementation(() => {
            const r = responses[call] ?? responses[responses.length - 1];
            call++;
            return makeMockStream(r.statusCode, r.body);
        }),
        on: (event: string, handler: (...args: unknown[]) => void) => { sessionEmitter.on(event, handler); return sessionEmitter; },
    };
}

// --- test suite ---

describe('apnsHelper - 403 InvalidProviderToken retry', () => {
    const origEnv = process.env;

    beforeEach(() => {
        // Reset all module state (cachedToken, apnsSession) between tests.
        jest.resetModules();

        process.env = {
            ...origEnv,
            NODE_ENV: 'production',
            AZURE_KEYVAULT_URL: 'https://mock-vault.vault.azure.net',
            APNS_KEY_SECRET_ID: 'mock-secret-name',
            APNS_KEY_ID: 'MOCK_KEY_ID',
            APNS_TEAM_ID: 'MOCK_TEAM_ID',
            APNS_BUNDLE_ID: 'com.example.mock',
        };
    });

    afterEach(() => {
        process.env = origEnv;
    });

    function setupMocks(session: ReturnType<typeof makeMockSession>) {
        // Swap in mocks before the module is (re-)required.
        jest.doMock('node:http2', () => ({ connect: jest.fn().mockReturnValue(session) }));

        jest.doMock('@azure/keyvault-secrets', () => ({
            SecretClient: jest.fn().mockImplementation(() => ({
                getSecret: jest.fn().mockResolvedValue({ value: 'mock-pem-value' }),
            })),
        }));

        jest.doMock('@azure/identity', () => ({ DefaultAzureCredential: jest.fn() }));

        // Bypass the real PEM parse + JWT sign so we don't need real key material.
        jest.doMock('jsonwebtoken', () => ({ sign: jest.fn().mockReturnValue('mock-jwt') }));
        jest.doMock('crypto', () => ({
            ...jest.requireActual<typeof import('crypto')>('crypto'),
            createPrivateKey: jest.fn().mockReturnValue({ asymmetricKeyType: 'ec' }),
        }));

        jest.doMock('../../sql/pushNotifications.queries', () => ({
            getPushTokensForUser: jest.fn().mockResolvedValue([{ push_token: 'device-token-abc' }]),
            deletePushToken: jest.fn().mockResolvedValue(undefined),
        }));

        jest.doMock('../../utilities/userHelpers', () => ({
            convertUserIdToBuffer: jest.fn((id: string) => Buffer.from(id)),
        }));
    }

    test('retries with a fresh token after 403 InvalidProviderToken and marks delivered', async () => {
        const session = makeMockSession([
            { statusCode: 403, body: JSON.stringify({ reason: 'InvalidProviderToken' }) },
            { statusCode: 200, body: '' },
        ]);
        setupMocks(session);

        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const { sendPushNotifications } = require('../../utilities/apnsHelper') as typeof import('../../utilities/apnsHelper');

        const result = await sendPushNotifications([{ userId: 'user-1', title: 'T', body: 'B' }]);

        expect(result.sent).toBe(1);
        expect(result.failed).toBe(0);
        expect(result.failures).toHaveLength(0);
        // Two requests should have been made: original + retry
        expect(session.request).toHaveBeenCalledTimes(2);
    });

    test('returns failure with "(after token refresh)" reason when retry also fails', async () => {
        const session = makeMockSession([
            { statusCode: 403, body: JSON.stringify({ reason: 'InvalidProviderToken' }) },
            { statusCode: 403, body: JSON.stringify({ reason: 'InvalidProviderToken' }) },
        ]);
        setupMocks(session);

        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const { sendPushNotifications } = require('../../utilities/apnsHelper') as typeof import('../../utilities/apnsHelper');

        const result = await sendPushNotifications([{ userId: 'user-1', title: 'T', body: 'B' }]);

        expect(result.sent).toBe(0);
        expect(result.failed).toBe(1);
        expect(result.failures[0].reason).toContain('after token refresh');
        expect(session.request).toHaveBeenCalledTimes(2);
    });

    test('does not retry on other 403 reasons (e.g. BadDeviceToken)', async () => {
        const session = makeMockSession([
            { statusCode: 403, body: JSON.stringify({ reason: 'BadDeviceToken' }) },
        ]);
        setupMocks(session);

        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const { sendPushNotifications } = require('../../utilities/apnsHelper') as typeof import('../../utilities/apnsHelper');

        const result = await sendPushNotifications([{ userId: 'user-1', title: 'T', body: 'B' }]);

        expect(result.sent).toBe(0);
        expect(result.failed).toBe(1);
        expect(result.failures[0].reason).not.toContain('after token refresh');
        expect(session.request).toHaveBeenCalledTimes(1);
    });

    test('signs JWT with iat claim (noTimestamp must not be set)', async () => {
        const jwtSignMock = jest.fn().mockReturnValue('mock-jwt');
        const session = makeMockSession([{ statusCode: 200, body: '' }]);
        setupMocks(session);
        jest.doMock('jsonwebtoken', () => ({ sign: jwtSignMock }));

        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const { sendPushNotifications } = require('../../utilities/apnsHelper') as typeof import('../../utilities/apnsHelper');
        await sendPushNotifications([{ userId: 'user-1', title: 'T', body: 'B' }]);

        expect(jwtSignMock).toHaveBeenCalledTimes(1);
        const [payload, , options] = jwtSignMock.mock.calls[0] as [Record<string, unknown>, unknown, Record<string, unknown>];
        expect(typeof payload.iat).toBe('number');
        expect(options).not.toHaveProperty('noTimestamp');
    });

    test('retries with a fresh token after 403 ExpiredProviderToken', async () => {
        const session = makeMockSession([
            { statusCode: 403, body: JSON.stringify({ reason: 'ExpiredProviderToken' }) },
            { statusCode: 200, body: '' },
        ]);
        setupMocks(session);

        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const { sendPushNotifications } = require('../../utilities/apnsHelper') as typeof import('../../utilities/apnsHelper');

        const result = await sendPushNotifications([{ userId: 'user-1', title: 'T', body: 'B' }]);

        expect(result.sent).toBe(1);
        expect(result.failed).toBe(0);
        expect(session.request).toHaveBeenCalledTimes(2);
    });
});
