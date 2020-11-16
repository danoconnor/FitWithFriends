// based on https://github.com/oauthjs/express-oauth-server/blob/master/examples/memory/model.js

/**
 * Constructor.
 */
function InMemoryCache() {
    this.clients = [
        {
            clientId: 'testclient',
            clientSecret: 'secret',
            redirectUris: ['https://localhost:1337'],
            grants: ['password', 'authorization_code'],
        }];
    this.tokens = [];
    this.users = [{ id: '123', username: 'test', password: 'test' }];
    this.authorizationCodes = [];
}

/**
 * Dump the cache.
 */
InMemoryCache.prototype.dump = function () {
    console.log('clients', this.clients);
    console.log('tokens', this.tokens);
    console.log('users', this.users);
};

/*
 * Get access token.
 */
InMemoryCache.prototype.getAccessToken = function (bearerToken) {
    //console.log('called getAccessToken, bearerToken=', bearerToken);
    var tokens = this.tokens.filter(function (token) {
        return token.accessToken === bearerToken;
    });

    return tokens.length ? tokens[0] : false;
};

/**
 * Get refresh token.
 */
InMemoryCache.prototype.getRefreshToken = function (bearerToken) {
    //console.log('called getRefreshToken, bearerToken=', bearerToken);
    var tokens = this.tokens.filter(function (token) {
        return token.refreshToken === bearerToken;
    });

    return tokens.length ? tokens[0] : false;
};

/**
 * Get client.
 */
InMemoryCache.prototype.getClient = function (clientId, clientSecret) {
    //console.log(`called InMemoryCache.getClient - clientId=${clientId}, clientSecret=${clientSecret}`);
    var clients = this.clients.filter(function (client) {
        return client.clientId === clientId;
    });
    //console.log('found clients: ' + clients.length);
    return clients.length ? clients[0] : false;
};

/**
 * Save token.
 */
InMemoryCache.prototype.saveToken = function (token, client, user) {
    //console.log('called saveToken', arguments);
    var newToken = {
        accessToken: token.accessToken,
        accessTokenExpiresAt: token.accessTokenExpiresAt,
        clientId: client.clientId,
        refreshToken: token.refreshToken,
        refreshTokenExpiresAt: token.refreshTokenExpiresAt,
        userId: user.id,

        //these are required in /node_modules/express-oauth-server/node_modules/oauth2-server/lib/models/token-model.js
        client: client,
        user: user,
        scope: null, //where are we taking scope from? maybe client?
    };
    this.tokens.push(newToken);
    return newToken;
};

/*
 * Get user.
 */
InMemoryCache.prototype.getUser = function (username, password) {
    var users = this.users.filter(function (user) {
        return user.username === username && user.password === password;
    });

    return users.length ? users[0] : false;
};

InMemoryCache.prototype.getUserFromClient = function () {
    //console.log('called prototype.getUserFromClient', arguments);
    //todo: find correct user.
    return this.users[0];
}

InMemoryCache.prototype.getAuthorizationCode = function (authorizationCode) {
    var codes = this.authorizationCodes.filter(function (code) {
        return code.accessToken === authorizationCode.accessToken
    });

    if (codes.length === 0) {
        return false
    }

    var code = codes[0];
    var client = this.getClient(code.clientId);

    var users = this.users.filter(function (user) {
        return user.id === code.userId
    });

    if (users.length === 0) {
        return false
    }

    var user = users[0];

    return {
        code: code.authorization_code,
        expiresAt: code.expires_at,
        redirectUri: code.redirect_uri,
        scope: code.scope,
        client: client, // with 'id' property
        user: user
    }
}

InMemoryCache.prototype.saveAuthorizationCode = function (authorizationCode) {
    this.authorizationCodes.push(authorizationCode)
    return authorizationCode
}

InMemoryCache.prototype.revokeAuthorizationCode = function (authorizationCode) {
    this.authorizationCodes = this.authorizationCodes.filter(function (code) {
        return code === authorizationCode
    });
}


/**
 * Export constructor.
 */
module.exports = InMemoryCache;