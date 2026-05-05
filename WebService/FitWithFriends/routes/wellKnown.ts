'use strict';
import * as express from 'express';
const router = express.Router();

router.get('/apple-app-site-association', function (req, res) {
    res.json({
        "applinks": {
            "details": [
                {
                    "appIDs": ["U7MJ9CBUMD.com.danoconnor.FitWithFriends"],
                    "components": [
                        { "/": "/joinCompetition" }
                    ]
                }
            ]
        }
    });
});

export default router;