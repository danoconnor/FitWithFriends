import ExpressOAuthServer from '@node-oauth/express-oauth-server';
import AppleIdTokenGrant from './AppleIdTokenGrant'
import AuthenticationModel from './oauthModel';

// Note: our custom apple_id_token grant type replaces the password grant
// because our app currently only supports Sign-In With Apple authentication
const server = new ExpressOAuthServer({
    model: new AuthenticationModel(),
    extendedGrantTypes: { 'apple_id_token': AppleIdTokenGrant },
    accessTokenLifetime:  60 * 60, // 1 hour
    refreshTokenLifetime: 60 * 60 * 24 * 365, // 1 year
    allowEmptyState: true,
    allowExtendedTokenAttributes: true,
    alwaysIssueNewRefreshToken: false
});

export default server;