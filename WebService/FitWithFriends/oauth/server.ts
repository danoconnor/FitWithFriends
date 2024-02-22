const OAuthServer = require('express-oauth-server')

// Note: our custom apple_id_token grant type replaces the password grant
// because our app currently only supports Sign-In With Apple authentication
module.exports = new OAuthServer({
    model: require('./model'),
    grants: ['refresh_token', 'apple_id_token'],
    accessTokenLifetime:  60 * 60, // 1 hour
    refreshTokenLifetime: 60 * 60 * 24 * 365, // 1 year
    allowEmptyState: true,
    allowExtendedTokenAttributes: true,
    alwaysIssueNewRefreshToken: false
})