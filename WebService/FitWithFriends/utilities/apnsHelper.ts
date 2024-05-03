import * as https from 'https';
import { DefaultAzureCredential } from '@azure/identity';
import { KeyClient } from '@azure/keyvault-keys';
import { CertificateClient } from '@azure/keyvault-certificates';
import * as PushNotificationQueries from '../sql/pushNotifications.queries';
import { convertUserIdToBuffer } from './userHelpers';
import PushNotificationPlatform from './enums/PushNotificationPlatform';

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
    
    const { cert, key } = await getAPNSCertAndKey();

}

/**
 * Get the APNS certificate and key from the keyvault
 * @returns The APNS certificate and key in PEM format
 */
async function getAPNSCertAndKey(): Promise<{ cert: string, key: string }> {
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

async function sendPushNotification(pushToken: string, notificationTitle: string, notificationBody: string, cert: string, key: string) {
    const options: https.RequestOptions = {
        hostname: 'api.push.apple.com',
        port: 443,
        path: '/3/device/' + pushToken,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        key: key,
        cert: cert
    };

    const payload = {
        aps: {
            alert: {
                title: notificationTitle,
                body: notificationBody
            }
        }
    };

    // TODO: handle error responses from APNS
    return new Promise((resolve, reject) => {
        const req = https.request(options, res => {
            let data = '';

            res.on('data', chunk => {
                data += chunk;
            });

            res.on('end', () => {
                console.log(`statusCode: ${res.statusCode}`);

                if (res.statusCode! >= 200 && res.statusCode! < 300) {
                    resolve(data);
                } else {
                    reject(new Error(`Request failed with status code ${res.statusCode}`));
                }
            });
        });

        req.on('error', error => {
            reject(error);
        });

        req.write(JSON.stringify(payload));
        req.end();
    });
}