var AppleIdTokenGrant = require('../oauth/AppleIdTokenGrant.js');
const express = require('express');
const oauthServer = require('../oauth/server.js');

const router = express.Router() // Instantiate a new router

router.post('/token', (req, res, next) => {
    next()
}, oauthServer.token({
    // Send back extra properties that the model sets on the created token
    // We want this so user ID is returned with the token
    allowExtendedTokenAttributes: true,
    extendedGrantTypes: {
        'apple_id_token': AppleIdTokenGrant // An id token acquired by the Sign-In With Apple process
    }
}));

module.exports = router