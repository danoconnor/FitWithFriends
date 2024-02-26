'use strict';
import { handleError } from '../utilities/errorHelpers';
import express from 'express';
const router = express.Router();

/* GET home page. */
router.get('/', function (req, res) {
    res.render('index', { title: 'Fit With Friends' });
});

// TODO: should we show an error/warning if the user agent isn't for iOS?
// For now we'll just assume that this page is running on an iOS device
router.get('/joinCompetition', function (req, res) {
    // All incoming query params are lowercased
    const competitionID = req.query['competitionid'];
    const competitionToken = req.query['competitiontoken'];

    if (!competitionID || !competitionToken) {
        handleError(null, 400, 'Missing required query param', res, true);
        return;
    }

    // TODO: Need the actual app store ID
    const appStoreUrl = 'itms-apps://itunes.apple.com/app/apple-store/id983156458';
    const appDeeplink = 'fitwithfriends://joinCompetition?competitionToken=' + competitionToken + '&competitionId=' + competitionID;

    res.render('joinCompetition', {
        title: 'Fit With Friends',
        appStoreUrl: appStoreUrl,
        appDeeplink: appDeeplink
    });
});

export default router;