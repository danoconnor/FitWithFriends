import * as express from 'express';

const adminSecret = process.env.ADMIN_AUTH_SECRET;

function authenticateAdmin(req: express.Request, res: express.Response, next: express.NextFunction) {  
    const authHeader = req.header('Authorization');
    if (!authHeader) {
        return res.sendStatus(401);
    }

    if (!adminSecret || adminSecret.length === 0) {
        return res.sendStatus(500);
    }

    if (authHeader === adminSecret) {
        return next();
    }

    return res.sendStatus(401);
}

export { authenticateAdmin }