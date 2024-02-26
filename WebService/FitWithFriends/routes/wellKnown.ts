'use strict';
import * as express from 'express';
const router = express.Router();

router.get('/apple-app-site-association', function (req, res) {
    res.json({
        "applinks": {
            "apps": [],
            "details": [
                {
                    "appID": "U7MJ9CBUMD.com.danoconnor.FitWithFriends",
                    "paths": ["/joinCompetition"]
                }
            ]
        }
    });
});

export default router;