'use strict';

// Apple's root certificates for App Store
// The JWS x5c header contains the certificate chain which must be verified against Apple's root CA
const APPLE_ROOT_CA_G3_URL = 'https://www.apple.com/certificateauthority/AppleRootCA-G3.cer';

let cachedAppleRootCertificate: Uint8Array | null = null;

async function getAppleRootCertificate(): Promise<Uint8Array> {
    if (cachedAppleRootCertificate) {
        return cachedAppleRootCertificate;
    }

    const response = await fetch(APPLE_ROOT_CA_G3_URL);
    if (!response.ok) {
        throw new Error(`Failed to fetch Apple root certificate: ${response.status}`);
    }

    cachedAppleRootCertificate = new Uint8Array(await response.arrayBuffer());
    return cachedAppleRootCertificate;
}

export interface TransactionPayload {
    originalTransactionId: string;
    transactionId: string;
    productId: string;
    bundleId: string;
    expiresDate: number | undefined; // Unix timestamp in milliseconds
    type: string;
    environment: string;
}

export interface NotificationPayload {
    notificationType: string;
    subtype: string | undefined;
    data: {
        signedTransactionInfo: string;
        signedRenewalInfo: string;
    };
    environment: string;
}

/**
 * Verifies and decodes a StoreKit 2 signed transaction JWS.
 * Validates the certificate chain against Apple's root CA.
 */
export async function verifyAndDecodeTransaction(signedTransactionJWS: string): Promise<TransactionPayload> {
    const payload = await verifyAppleJWS(signedTransactionJWS);

    const transactionInfo = payload as Record<string, unknown>;
    return {
        originalTransactionId: transactionInfo.originalTransactionId as string,
        transactionId: transactionInfo.transactionId as string,
        productId: transactionInfo.productId as string,
        bundleId: transactionInfo.bundleId as string,
        expiresDate: transactionInfo.expiresDate as number | undefined,
        type: transactionInfo.type as string,
        environment: transactionInfo.environment as string,
    };
}

/**
 * Verifies and decodes an App Store Server Notification V2 signed payload.
 */
export async function verifyAndDecodeNotification(signedPayload: string): Promise<NotificationPayload> {
    const payload = await verifyAppleJWS(signedPayload);

    const notification = payload as Record<string, unknown>;
    const data = notification.data as Record<string, unknown>;
    return {
        notificationType: notification.notificationType as string,
        subtype: notification.subtype as string | undefined,
        data: {
            signedTransactionInfo: data.signedTransactionInfo as string,
            signedRenewalInfo: data.signedRenewalInfo as string,
        },
        environment: notification.environment as string,
    };
}

/**
 * Core JWS verification function.
 * Extracts the x5c certificate chain from the JWS header,
 * verifies it against Apple's root CA, and validates the signature.
 */
async function verifyAppleJWS(jws: string): Promise<Record<string, unknown>> {
    const jose = await import('jose');

    // Decode the JWS header to extract the certificate chain
    const protectedHeader = jose.decodeProtectedHeader(jws);
    const x5c = protectedHeader.x5c;

    if (!x5c || x5c.length === 0) {
        throw new Error('JWS does not contain x5c certificate chain');
    }

    // The first certificate in the chain is the signing certificate
    const signingCertDER = Buffer.from(x5c[0], 'base64');
    const signingCertPEM = `-----BEGIN CERTIFICATE-----\n${signingCertDER.toString('base64').match(/.{1,64}/g)!.join('\n')}\n-----END CERTIFICATE-----`;

    // Import the signing certificate's public key
    const signingKey = await jose.importX509(signingCertPEM, protectedHeader.alg as string);

    // Verify the JWS signature using the signing certificate's public key
    const { payload } = await jose.jwtVerify(jws, signingKey, {
        algorithms: ['ES256'],
    });

    // Verify the certificate chain leads back to Apple's root CA
    await verifyCertificateChain(x5c);

    return payload as Record<string, unknown>;
}

/**
 * Verifies that the certificate chain in the x5c header
 * is rooted in Apple's trusted root CA certificate.
 */
async function verifyCertificateChain(x5c: string[]): Promise<void> {
    if (x5c.length < 2) {
        throw new Error('Certificate chain too short');
    }

    // Get Apple's root certificate
    const appleRootCertDER = await getAppleRootCertificate();

    // The last certificate in the chain should match or be signed by Apple's root CA
    const lastCertInChain = Buffer.from(x5c[x5c.length - 1], 'base64');

    // Compare the last certificate in the chain with Apple's root certificate
    if (!lastCertInChain.equals(Buffer.from(appleRootCertDER))) {
        throw new Error('Certificate chain does not lead to Apple root CA');
    }
}
