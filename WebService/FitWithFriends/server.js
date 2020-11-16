const OAuthServer = require('express-oauth-server')
// const InMemoryModel = require('./inMemoryModel')

module.exports = new OAuthServer({
    model: require('./model'),
    grants: ['authorization_code', 'refresh_token'],
    accessTokenLifetime: 60 * 60 * 24, // 24 hours, or 1 day
    allowEmptyState: true,
    allowExtendedTokenAttributes: true
})