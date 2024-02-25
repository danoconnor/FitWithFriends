"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRandomToken = exports.getHash = exports.getRandomString = void 0;
var crypto = require("crypto");
function getRandomString(length) {
    if (length === void 0) { length = 64; }
    return crypto.randomBytes(Math.ceil(length / 2))
        .toString('hex')
        .slice(0, length);
}
exports.getRandomString = getRandomString;
function getHash(value, salt, algorithm) {
    if (algorithm === void 0) { algorithm = 'sha512'; }
    var hash = crypto.createHmac(algorithm, salt);
    hash.update(value);
    return hash.digest('hex');
}
exports.getHash = getHash;
function getRandomToken() {
    var bytes = crypto.randomBytes(256);
    return crypto.createHash('sha1')
        .update(bytes)
        .digest('hex');
}
exports.getRandomToken = getRandomToken;
