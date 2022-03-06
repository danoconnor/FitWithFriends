'use strict';
const errorHelpers = require('../utilities/errorHelpers');
const express = require('express');
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
        errorHelpers.handleError(null, 400, 'Missing required query param', res, true);
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

module.exports = router;
