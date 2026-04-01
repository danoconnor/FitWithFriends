'use strict';
import express = require('express');
const router = express.Router();
import { handleError } from '../utilities/errorHelpers';

router.get('/iosBuildVersions', function (req, res) {
    const recommendedBuild = process.env.FWF_IOS_RECOMMENDED_BUILD;
    const requiredBuild = process.env.FWF_IOS_REQUIRED_BUILD;

    if (!recommendedBuild || !requiredBuild) {
        handleError(null, 500, 'iOS build version environment variables are not configured', res);
        return;
    }

    res.json({
        recommendedBuild,
        requiredBuild
    });
});

export default router;
