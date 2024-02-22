var crypto = require('crypto');
module.exports.getRandomString = function (length) {
    if (length === void 0) { length = 64; }
    return crypto.randomBytes(Math.ceil(length / 2))
        .toString('hex')
        .slice(0, length);
};
module.exports.getHash = function (value, salt, algorithm) {
    if (algorithm === void 0) { algorithm = 'sha512'; }
    var hash = crypto.createHmac(algorithm, salt);
    hash.update(value);
    return hash.digest('hex');
};
module.exports.getRandomToken = function () {
    var bytes = crypto.randomBytes(256);
    return crypto.createHash('sha1')
        .update(bytes)
        .digest('hex');
};
