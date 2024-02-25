import crypto = require('crypto');

export function getRandomString(length = 64) {
    return crypto.randomBytes(Math.ceil(length / 2))
        .toString('hex')
        .slice(0, length);
}

export function getHash(value: string, salt: string, algorithm = 'sha512') {
    var hash = crypto.createHmac(algorithm, salt);
    hash.update(value);
    return hash.digest('hex');
} 

export function getRandomToken(): string {
    const bytes = crypto.randomBytes(256)
    return crypto.createHash('sha1')
        .update(bytes)
        .digest('hex');
}