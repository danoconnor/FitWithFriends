const crypto = require('crypto')

module.exports.getRandomString = function(length = 64) {
    return crypto.randomBytes(Math.ceil(length / 2))
        .toString('hex')
        .slice(0, length);
}

module.exports.getHash = function(value, salt, algorithm = 'sha512') {
    var hash = crypto.createHmac(algorithm, salt);
    hash.update(value);
    return hash.digest('hex');
} 