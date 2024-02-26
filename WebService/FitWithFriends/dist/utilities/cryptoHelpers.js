"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.signData = exports.getRandomToken = exports.getHash = exports.getRandomString = void 0;
const crypto = require("crypto");
function getRandomString(length = 64) {
    return crypto.randomBytes(Math.ceil(length / 2))
        .toString('hex')
        .slice(0, length);
}
exports.getRandomString = getRandomString;
function getHash(value, salt, algorithm = 'sha512') {
    var hash = crypto.createHmac(algorithm, salt);
    hash.update(value);
    return hash.digest('hex');
}
exports.getHash = getHash;
function getRandomToken() {
    const bytes = crypto.randomBytes(256);
    return crypto.createHash('sha1')
        .update(bytes)
        .digest('hex');
}
exports.getRandomToken = getRandomToken;
function signData(data, privateKey, signingAlgorithm) {
    const sign = crypto.createSign(signingAlgorithm);
    sign.update(data);
    return sign.sign(privateKey);
}
exports.signData = signData;
