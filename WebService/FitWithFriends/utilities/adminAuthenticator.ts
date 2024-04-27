import * as express from 'express';

const adminSecret = process.env.FWF_ADMIN_AUTH_SECRET;

// Middleware helper function to authenticate admin requests
// Used to authenticate our cron job that triggers push notifications and other scheduled tasks
// Expects an Authorization header with the admin secret
function authenticateAdmin(req: express.Request, res: express.Response, next: express.NextFunction) {  
    const authHeader = req.header('Authorization');
    if (!authHeader) {
        return res.sendStatus(401);
    }

    if (!adminSecret || adminSecret.length === 0) {
        // We haven't set the environment var correctly
        // Don't want to allow a potentially unauthenticated request to go through
        return res.sendStatus(500);
    }

    if (authHeader === adminSecret) {
        return next();
    }

    return res.sendStatus(401);
}

export { authenticateAdmin }