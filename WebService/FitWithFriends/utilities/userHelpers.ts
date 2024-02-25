export function convertUserIdToBuffer(userId: string): Buffer {
    return Buffer.from(userId, 'hex');
}

export function convertBufferToUserId(userId: Buffer): string {
    return userId.toString('hex');
}