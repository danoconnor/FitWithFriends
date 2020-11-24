const OAuthServer = require('express-oauth-server')

module.exports = new OAuthServer({
    model: require('./model'),
    grants: ['refresh_token', 'password'],
    accessTokenLifetime: 60 * 60 * 24, // 24 hours, or 1 day
    allowEmptyState: true,
    allowExtendedTokenAttributes: true
})