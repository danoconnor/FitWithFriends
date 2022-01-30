const OAuthServer = require('express-oauth-server')

module.exports = new OAuthServer({
    model: require('./model'),
    grants: ['refresh_token', 'password'],
    accessTokenLifetime:  60 * 60 * 24, // 1 day
    refreshTokenLifetime: 60 * 60 * 24 * 365, // 1 year
    allowEmptyState: true,
    allowExtendedTokenAttributes: true
})