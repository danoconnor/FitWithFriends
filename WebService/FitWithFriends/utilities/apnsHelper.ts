import * as https from 'https';
import jwt from 'jsonwebtoken';
import { DefaultAzureCredential } from '@azure/identity';
import { SecretClient } from '@azure/keyvault-secrets';
import * as PushNotificationQueries from '../sql/pushNotifications.queries';
import { convertUserIdToBuffer } from './userHelpers';

export interface Notification {
    userId: string;
    title: string;
    body: string;
}

// Cache the token and its expiry to avoid re-signing on every request.
// APNs tokens are valid for 1 hour; we refresh 5 minutes early.
let cachedToken: string | null = null;
let cachedTokenExpiresAt: number = 0;

export async function sendPushNotifications(notifications: Notification[]) {
    if (notifications.length === 0) {
        console.log('No notifications to send');
        return;
    }

    // Get distinct user IDs from notifications
    const userIds = Array.from(new Set(notifications.map(n => n.userId)));
    if (userIds.length === 0) {
        console.log('No distinct user IDs found in notifications');
        return;
    }

    const [pushTokenResults, apnsToken] = await Promise.all([
        Promise.all(userIds.map(userId => getPushTokenForUser(userId))),
        getAPNSToken()
    ]);
    const usersToPushTokens = Object.fromEntries(
        pushTokenResults.map(result => [result.userId, result.tokens])
    );

    // Create an HTTPS agent to reuse the TLS connection for multiple requests
    const httpsAgent = new https.Agent({ keepAlive: true });

    // Create an entry for each notification/push token pair that we are going to send
    const notificationTokenPairs: Array<{
        userId: string;
        pushToken: string;
        title: string;
        body: string;
    }> = [];
    for (const notification of notifications) {
        const tokens = usersToPushTokens[notification.userId] || [];
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
        await Promise.all(
            batch.map(({ userId, pushToken, title, body }) =>
                sendPushNotification(
                    httpsAgent,
                    userId,
                    pushToken,
                    title,
                    body,
                    apnsToken
                )
            )
        );
    }
}

async function getPushTokenForUser(userId: string): Promise<{ userId: string, tokens: string[] }> {
    const pushTokens = await PushNotificationQueries.getPushTokensForUser({ userId: convertUserIdToBuffer(userId) });
    if (pushTokens.length === 0) {
        console.warn(`No push tokens found for userId ${userId}`);
        return { userId, tokens: [] };
    }

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

    const secretClient = new SecretClient(vaultUrl, new DefaultAzureCredential());
    const secret = await secretClient.getSecret(secretId);
    if (!secret.value) {
        throw new Error('APNS secret value is empty in Key Vault');
    }

    const token = jwt.sign({ iss: teamId, iat: nowSeconds }, secret.value, {
        algorithm: 'ES256',
        keyid: apnsKeyId,
        noTimestamp: true,
    });

    // Cache for 55 minutes (token is valid for 60)
    cachedToken = token;
    cachedTokenExpiresAt = nowSeconds + 55 * 60;

    return token;
}

async function sendPushNotification(httpsAgent: https.Agent, userId: string, pushToken: string, notificationTitle: string, notificationBody: string, apnsToken: string) {
    if (isTestEnvironment()) {
        console.log(`Mock push notification to userId ${userId} with token ${pushToken}: ${notificationTitle} - ${notificationBody}`);
        return;
    }

    const bundleId = process.env.APNS_BUNDLE_ID;
    if (!bundleId) {
        throw new Error('Missing required APNS_BUNDLE_ID environment variable');
    }

    const options: https.RequestOptions = {
        hostname: 'api.push.apple.com',
        port: 443,
        path: '/3/device/' + pushToken,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'apns-push-type': 'alert',
            'apns-topic': bundleId,
            'authorization': `bearer ${apnsToken}`,
        },
        agent: httpsAgent
    };

    // See https://developer.apple.com/documentation/usernotifications/generating-a-remote-notification#Create-the-JSON-payload
    const payload = {
        aps: {
            alert: {
                title: notificationTitle,
                body: notificationBody
            }
        }
    };

    // See https://developer.apple.com/documentation/usernotifications/handling-notification-responses-from-apns
    return new Promise<void>((resolve, reject) => {
        const req = https.request(options, res => {
            let data = '';

            res.on('data', chunk => {
                data += chunk;
            });

            res.on('end', async () => {
                const statusCode = res.statusCode;
                if (!statusCode) {
                    reject(new Error('No status code in response'));
                    return;
                }

                console.log(`statusCode: ${statusCode}`);

                if (statusCode >= 200 && statusCode < 300) {
                    resolve();
                } else if (statusCode === 410) {
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
                    resolve();
                } else {
                    // Do not reject here so we can continue processing other notifications
                    console.error(`Request failed with status code ${statusCode}. Details: ${data}`);
                    resolve();
                }
            });
        });

        req.on('error', error => {
            // Do not reject here so we can continue processing other notifications
            console.error('Error sending push notification:', error);
            resolve();
        });

        req.write(JSON.stringify(payload));
        req.end();
    });
}

function isTestEnvironment(): boolean {
    return process.env.NODE_ENV === 'test' || process.env.NODE_ENV === 'development';
}
