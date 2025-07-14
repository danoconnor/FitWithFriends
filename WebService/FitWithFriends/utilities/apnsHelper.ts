import * as https from 'https';
import { DefaultAzureCredential } from '@azure/identity';
import { KeyClient } from '@azure/keyvault-keys';
import { CertificateClient } from '@azure/keyvault-certificates';
import * as PushNotificationQueries from '../sql/pushNotifications.queries';
import { convertUserIdToBuffer } from './userHelpers';

export interface Notification {
    userId: string;
    title: string;
    body: string;
}

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
    
    const apnsCredentialPromise = getAPNSCertAndKey();
    const pushTokenResults = await Promise.all(userIds.map(userId => getPushTokenForUser(userId)));
    const usersToPushTokens = Object.fromEntries(
        pushTokenResults.map(result => [result.userId, result.tokens])
    );

    const { cert, key } = await apnsCredentialPromise;

    const httpsAgent = new https.Agent();

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
                    cert,
                    key
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

/**
 * Get the APNS certificate and key from the keyvault
 * @returns The APNS certificate and key in PEM format
 */
async function getAPNSCertAndKey(): Promise<{ cert: string, key: string }> {
    if (isTestEnvironment()) {
        // In test environment, use a mock certificate and key
        return {
            cert: '-----BEGIN CERTIFICATE-----\nYOUR_TEST_CERTIFICATE_HERE\n-----END CERTIFICATE-----',
            key: '-----BEGIN PRIVATE KEY-----\nYOUR_TEST_KEY_HERE\n-----END PRIVATE KEY-----'
        };
    }

    // Get the APNS key from the keyvault
    const vaultUrl = process.env.AZURE_KEYVAULT_URL;
    const apnsKeyId = process.env.APNS_KEY_ID;
    const apnsCertificateId = process.env.APNS_CERTIFICATE_ID;

    if (!vaultUrl || !apnsKeyId || !apnsCertificateId) {
        throw new Error('Missing required APNS environment variables');
    }

    const credential = new DefaultAzureCredential();
    const keyClient = new KeyClient(vaultUrl, credential);
    const key = await keyClient.getKey(apnsKeyId);
    const keyPem = key.key.toString();

    const certificateClient = new CertificateClient(vaultUrl, credential);
    const certificate = await certificateClient.getCertificate(apnsCertificateId);
    const certificatePem = certificate.cer.toString();

    return { cert: certificatePem, key: keyPem };
}

/**
 * Send a push notification to a device
 * @param httpsAgent The agent to use for the HTTPS request. This resuses the TLS connection for multiple requests
 * @param userId The user ID to whom the notification is being sent
 * @param pushToken The push token of the device
 * @param notificationTitle The title of the notification
 * @param notificationBody The body of the notification
 * @param cert The APNS certificate in PEM format
 * @param key The APNS key in PEM format
 */
async function sendPushNotification(httpsAgent: https.Agent, userId: string, pushToken: string, notificationTitle: string, notificationBody: string, cert: string, key: string) {
    if (isTestEnvironment()) {
        console.log(`Mock push notification to userId ${userId} with token ${pushToken}: ${notificationTitle} - ${notificationBody}`);
        return;
    }

    const options: https.RequestOptions = {
        hostname: 'api.push.apple.com',
        port: 443,
        path: '/3/device/' + pushToken,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'apns-push-type': 'alert',
        },
        key: key,
        cert: cert,
        agent: httpsAgent // Reuse the agent to send multiple POST requests over the same TLS connection
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
                        console.error('Failed to delete invalid push token for userId ${userId}:', err);
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