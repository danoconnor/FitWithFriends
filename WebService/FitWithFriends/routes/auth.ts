import express, { NextFunction, Request, Response } from 'express';
import oauthServer from '../oauth/server.js';
import FWFErrorCodes from '../utilities/enums/FWFErrorCodes.js';
import { handleError } from '../utilities/errorHelpers.js';

const router = express.Router() // Instantiate a new router

router.post('/token', (_req, _res, next) => {
    console.log('Received request for /token route');
    next()
}, oauthServer.token({
    // Send back extra properties that the model sets on the created token
    // We want this so user ID is returned with the token
    allowExtendedTokenAttributes: true
}));

// Error handler only for /token
router.use('/token', (err: any, req: Request, res: Response, next: NextFunction) => {
    // Custom error handler so we include the custom error code for cases that need it
    handleError(err, err.code, err.name, res, true, err.customErrorCode);
});

export default router;