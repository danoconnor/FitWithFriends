import express from 'express';
import oauthServer from '../oauth/server.js';

const router = express.Router() // Instantiate a new router

router.post('/token', (_req, _res, next) => {
    console.log('IN POST /token');
    next()
}, oauthServer.token({
    // Send back extra properties that the model sets on the created token
    // We want this so user ID is returned with the token
    allowExtendedTokenAttributes: true
}));

export default router;