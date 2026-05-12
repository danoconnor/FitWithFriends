import jwt from 'jsonwebtoken';
import { createPrivateKey } from 'crypto';
import * as http2 from 'node:http2';
import { DefaultAzureCredential } from '@azure/identity';
import { SecretClient } from '@azure/keyvault-secrets';
import * as PushNotificationQueries from '../sql/pushNotifications.queries';
import { convertUserIdToBuffer } from './userHelpers';

export interface Notification {
    userId: string;
    title: string;
    body: string;
}

export interface SendResult {
    sent: number;
    failed: number;
    failures: Array<{ userId: string; reason: string }>;
}

// Cache the token and its expiry to avoid re-signing on every request.
// APNs tokens are valid for 1 hour; we refresh 5 minutes early.
let cachedToken: string | null = null;
let cachedTokenExpiresAt: number = 0;

export async function sendPushNotifications(notifications: Notification[]): Promise<SendResult> {
    if (notifications.length === 0) {
        console.log('No notifications to send');
        return { sent: 0, failed: 0, failures: [] };
    }

    // Get distinct user IDs from notifications
    const userIds = Array.from(new Set(notifications.map(n => n.userId)));
    if (userIds.length === 0) {
        console.log('No distinct user IDs found in notifications');
        return { sent: 0, failed: 0, failures: [] };
    }

    const [pushTokenResults, apnsToken] = await Promise.all([
        Promise.all(userIds.map(userId => getPushTokenForUser(userId))),
        getAPNSToken()
    ]);
    const usersToPushTokens = Object.fromEntries(
        pushTokenResults.map(result => [result.userId, result.tokens])
    );

    // Create an entry for each notification/push token pair that we are going to send.
    // Notifications for users with no registered token count as immediate failures.
    let sent = 0;
    let failed = 0;
    const failures: Array<{ userId: string; reason: string }> = [];
    const notificationTokenPairs: Array<{
        userId: string;
        pushToken: string;
        title: string;
        body: string;
    }> = [];
    for (const notification of notifications) {
        const tokens = usersToPushTokens[notification.userId] || [];
        if (tokens.length === 0) {
            console.warn(`No push tokens found for userId ${notification.userId} — notification not delivered`);
            failed++;
            failures.push({ userId: notification.userId, reason: 'no registered push token' });
        }
        for (const pushToken of tokens) {
            notificationTokenPairs.push({
                userId: notification.userId,
                pushToken,
                title: notification.title,
                body: notification.body
            });
        }
    }

    // Send up to 10 outgoing APNS requests in parallel
    const batchSize = 10;
    for (let i = 0; i < notificationTokenPairs.length; i += batchSize) {
        const batch = notificationTokenPairs.slice(i, i + batchSize);
        const results = await Promise.all(
            batch.map(({ userId, pushToken, title, body }) =>
                sendPushNotification(userId, pushToken, title, body, apnsToken)
            )
        );
        for (let j = 0; j < results.length; j++) {
            if (results[j].delivered) {
                sent++;
            } else {
                failed++;
                failures.push({ userId: batch[j].userId, reason: results[j].reason });
            }
        }
    }

    return { sent, failed, failures };
}

async function getPushTokenForUser(userId: string): Promise<{ userId: string, tokens: string[] }> {
    const pushTokens = await PushNotificationQueries.getPushTokensForUser({ userId: convertUserIdToBuffer(userId) });
    return { userId, tokens: pushTokens.map(token => token.push_token) };
}

// Returns a valid APNs bearer token, using the cached one if still fresh.
async function getAPNSToken(): Promise<string> {
    if (isTestEnvironment()) {
        return 'test-apns-token';
    }

    const nowSeconds = Math.floor(Date.now() / 1000);
    if (cachedToken && nowSeconds < cachedTokenExpiresAt) {
        return cachedToken;
    }

    const vaultUrl = process.env.AZURE_KEYVAULT_URL;
    const secretId = process.env.APNS_KEY_SECRET_ID;
    const apnsKeyId = process.env.APNS_KEY_ID;
    const teamId = process.env.APNS_TEAM_ID;

    if (!vaultUrl || !secretId || !apnsKeyId || !teamId) {
        throw new Error('Missing required APNS environment variables');
    }

    // Secret names can only contain alphanumeric characters and hyphens.
    // A full URL in APNS_KEY_SECRET_ID is a common misconfiguration that causes 400.
    const secretNameValid = /^[a-zA-Z0-9-]+$/.test(secretId);
    if (!secretNameValid) {
        throw new Error('APNS_KEY_SECRET_ID is not a valid Key Vault secret name (only alphanumeric + hyphens allowed). If it looks like a URL, set it to just the secret name.');
    }

    let secret: Awaited<ReturnType<SecretClient['getSecret']>>;
    try {
        const secretClient = new SecretClient(vaultUrl, new DefaultAzureCredential());
        secret = await secretClient.getSecret(secretId);
    } catch (err: unknown) {
        const e = err as Record<string, unknown>;
        const statusCode = e?.['statusCode'];
        // 'details' is the parsed Key Vault response body: { error: { code, message } }
        // Log only the code — the message may contain the secret name.
        const kvErrorCode = (e?.['details'] as Record<string, unknown>)?.['error']
            ? ((e['details'] as Record<string, unknown>)['error'] as Record<string, unknown>)?.['code']
            : undefined;
        console.error(`Key Vault getSecret failed: statusCode=${statusCode}, kvErrorCode=${kvErrorCode}`);
        throw err;
    }
    if (!secret.value) {
        throw new Error('APNS secret value is empty in Key Vault');
    }

    const privateKey = parsePemKey(secret.value);
    const token = jwt.sign({ iss: teamId, iat: nowSeconds }, privateKey, {
        algorithm: 'ES256',
        keyid: apnsKeyId,
        noTimestamp: true,
    });

    // Decode the JWT header and payload (not the signature) for diagnostic logging.
    // Both parts are base64url-encoded JSON; the signature is opaque and not logged.
    try {
        const [headerB64, payloadB64] = token.split('.');
        const header = JSON.parse(Buffer.from(headerB64, 'base64url').toString());
        const payload = JSON.parse(Buffer.from(payloadB64, 'base64url').toString());
        console.log(`APNs JWT header: ${JSON.stringify(header)}`);
        console.log(`APNs JWT payload: ${JSON.stringify(payload)}`);
    } catch {
        console.warn('Could not decode APNs JWT for diagnostic logging');
    }

    // Cache for 55 minutes (token is valid for 60)
    cachedToken = token;
    cachedTokenExpiresAt = nowSeconds + 55 * 60;

    return token;
}

// Reuse a single HTTP/2 session across requests — APNs multiplexes over one connection.
// node:http2 is used directly because Node.js's built-in fetch (undici) only advertises
// http/1.1 in ALPN by default (allowH2 is false), and APNs requires HTTP/2.
let apnsSession: http2.ClientHttp2Session | null = null;

function getApnsSession(): http2.ClientHttp2Session {
    if (!apnsSession || apnsSession.destroyed || apnsSession.closed) {
        apnsSession = http2.connect('https://api.push.apple.com');
        apnsSession.on('error', (err) => {
            console.error('APNs HTTP/2 session error:', err);
            apnsSession = null;
        });
        apnsSession.on('close', () => { apnsSession = null; });
    }
    return apnsSession;
}

function makeApnsRequest(path: string, bodyStr: string, apnsToken: string, bundleId: string): Promise<{ statusCode: number; body: string }> {
    return new Promise((resolve, reject) => {
        const session = getApnsSession();
        const req = session.request({
            ':method': 'POST',
            ':path': path,
            'content-type': 'application/json',
            'content-length': String(Buffer.byteLength(bodyStr)),
            'apns-push-type': 'alert',
            'apns-topic': bundleId,
            'authorization': `bearer ${apnsToken}`,
        });

        let statusCode = 0;
        req.on('response', (headers) => { statusCode = headers[':status'] as number; });

        let responseBody = '';
        req.on('data', (chunk: Buffer) => { responseBody += chunk.toString(); });
        req.on('end', () => resolve({ statusCode, body: responseBody }));
        req.on('error', reject);

        req.write(bodyStr);
        req.end();
    });
}

async function sendPushNotification(userId: string, pushToken: string, notificationTitle: string, notificationBody: string, apnsToken: string): Promise<{ delivered: boolean; reason: string }> {
    if (isTestEnvironment()) {
        console.log(`Mock push notification to userId ${userId} with token ${pushToken}: ${notificationTitle} - ${notificationBody}`);
        return { delivered: true, reason: '' };
    }

    const bundleId = process.env.APNS_BUNDLE_ID;
    if (!bundleId) {
        throw new Error('Missing required APNS_BUNDLE_ID environment variable');
    }

    // See https://developer.apple.com/documentation/usernotifications/generating-a-remote-notification#Create-the-JSON-payload
    const payload = {
        aps: {
            alert: {
                title: notificationTitle,
                body: notificationBody
            }
        }
    };

    const bodyStr = JSON.stringify(payload);

    try {
        // See https://developer.apple.com/documentation/usernotifications/handling-notification-responses-from-apns
        const { statusCode, body: data } = await makeApnsRequest(`/3/device/${pushToken}`, bodyStr, apnsToken, bundleId);
        console.log(`APNs statusCode: ${statusCode}`);

        if (statusCode === 410) {
            // 410: The device token is no longer valid, delete it from the database
            try {
                await PushNotificationQueries.deletePushToken({
                    userId: convertUserIdToBuffer(userId),
                    pushToken: pushToken
                });
                console.warn(`Deleted invalid push token for userId ${userId}`);
            } catch (err) {
                console.error(`Failed to delete invalid push token for userId ${userId}:`, err);
            }
            return { delivered: false, reason: 'APNs 410: device token no longer valid (token deleted)' };
        } else if (statusCode === 403) {
            let apnsReason = '';
            try { apnsReason = (JSON.parse(data) as { reason?: string }).reason ?? ''; } catch { /* non-JSON body */ }
            if (apnsReason === 'InvalidProviderToken' || apnsReason === 'ExpiredProviderToken') {
                // APNs rejected our JWT — invalidate the cache and retry once with a fresh token.
                // This handles mid-run token expiry or revocation without failing the whole batch.
                console.warn(`APNs 403 ${apnsReason} for userId ${userId} — refreshing token and retrying`);
                cachedToken = null;
                cachedTokenExpiresAt = 0;
                const freshToken = await getAPNSToken();
                const retry = await makeApnsRequest(`/3/device/${pushToken}`, bodyStr, freshToken, bundleId);
                if (retry.statusCode >= 200 && retry.statusCode < 300) {
                    return { delivered: true, reason: '' };
                }
                const retryReason = `APNs HTTP ${retry.statusCode} (after token refresh): ${retry.body}`;
                console.error(`APNs retry failed for userId ${userId}: ${retryReason}`);
                return { delivered: false, reason: retryReason };
            }
            const reason = `APNs HTTP 403: ${data}`;
            console.error(`APNs request failed with status code 403 for userId ${userId}. Details: ${data}`);
            return { delivered: false, reason };
        } else if (statusCode < 200 || statusCode >= 300) {
            // Do not throw so we can continue processing other notifications
            const reason = `APNs HTTP ${statusCode}: ${data}`;
            console.error(`APNs request failed with status code ${statusCode}. Details: ${data}`);
            return { delivered: false, reason };
        }

        return { delivered: true, reason: '' };
    } catch (error) {
        const reason = `network error: ${(error as Error).message}`;
        console.error('Error sending push notification:', error);
        return { delivered: false, reason };
    }
}

// Parse and normalize an EC/PKCS8 private key stored in Key Vault.
// Key Vault can return the PEM with literal \n sequences, \r\n line endings,
// \r characters, or as a fully flattened single line. We reconstruct the PEM
// from scratch so Node.js crypto can always parse it, then return a KeyObject
// so jwt.sign recognizes it as asymmetric without ambiguity.
function parsePemKey(raw: string): ReturnType<typeof createPrivateKey> {
    // Decode all common escape/newline variants to real newlines
    const decoded = raw
        .replace(/\\r\\n/g, '\n')
        .replace(/\\n/g, '\n')
        .replace(/\\r/g, '\n')
        .replace(/\r\n/g, '\n')
        .replace(/\r/g, '\n');

    const isPkcs8 = decoded.includes('BEGIN PRIVATE KEY');
    const label = isPkcs8 ? 'PRIVATE KEY' : 'EC PRIVATE KEY';

    // Extract the raw base64 content between the PEM delimiters.
    // Using a regex handles both normally-formatted PEMs and fully-flat ones
    // (where the header and footer are concatenated directly to the base64 content).
    const pemMatch = decoded.match(/-----BEGIN [^-]+-----([A-Za-z0-9+/=\s]+)-----END [^-]+-----/);
    const base64 = pemMatch
        ? pemMatch[1].replace(/\s/g, '')
        : decoded.split('\n').map(l => l.trim()).filter(l => l && !l.startsWith('-----')).join('');

    // Re-wrap at the standard PEM line length of 64 characters
    const wrapped = (base64.match(/.{1,64}/g) ?? []).join('\n');
    const pem = `-----BEGIN ${label}-----\n${wrapped}\n-----END ${label}-----`;

    try {
        return createPrivateKey(pem);
    } catch (err) {
        throw new Error(`Failed to parse APNS private key: ${(err as Error).message}`);
    }
}

function isTestEnvironment(): boolean {
    return process.env.NODE_ENV === 'test' || process.env.NODE_ENV === 'development';
}
