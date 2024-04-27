'use strict';
import * as express from 'express';
const router = express.Router();

router.post('/performDailyTasks', function (req, res) {
    // TODO: find competitions that are ending and send push notifications and archive completed competitions
    // TODO: Cleanup expired tokens
});

export default router;