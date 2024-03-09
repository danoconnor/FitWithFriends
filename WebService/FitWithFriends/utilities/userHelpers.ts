/* Our database stores user ids as hex data, so we need to convert them to and from buffers for database queries. */
export function convertUserIdToBuffer(userId: string): Buffer {
    return Buffer.from(userId, 'hex');
}

/* Our database stores user ids as hex data, so we need to convert them to and from buffers for database queries. */
export function convertBufferToUserId(userId: Buffer): string {
    return userId.toString('hex');
}