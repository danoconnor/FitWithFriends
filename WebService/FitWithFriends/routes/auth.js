var AppleIdTokenGrant = require('../oauth/AppleIdTokenGrant.js');
const express = require('express');
const oauthServer = require('../oauth/server.js');

const { DefaultAzureCredential } = require('@azure/identity');
const { CryptographyClient } = require('@azure/keyvault-keys');
const { SecretClient } = require('@azure/keyvault-secrets');

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

router.get('/test', (req, res) => {
    signWithAzureKeyvault('some data to sign', 'RS256')
        .then(result => {
            const signature = Buffer.from(result.result).toString('base64')
                .replace(/=/g, '')
                .replace(/\+/g, '-')
                .replace(/\//g, '_');

            res.send(signature);
        })
        .catch(error => {
            res.send(error);
        })
})

function signWithAzureKeyvault(dataToSign, signingAlgorithm) {
    const signingKeyId = process.env.ACCESS_TOKEN_SIGNING_KID;

    // Need to set AZURE_TENANT_ID, AZURE_CLIENT_ID, and AZURE_CLIENT_SECRET environment variables
    // for the credential to work
    const credential = new DefaultAzureCredential();
    const cryptographyClient = new CryptographyClient(signingKeyId, credential);

    return cryptographyClient.signData(signingAlgorithm, Buffer.from(dataToSign));
}

module.exports = router