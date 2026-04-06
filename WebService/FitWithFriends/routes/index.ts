'use strict';
import { handleError } from '../utilities/errorHelpers';
import express from 'express';
import { UAParser } from 'ua-parser-js';
const router = express.Router();

/* GET home page. */
router.get('/', function (req, res) {
const appStoreUrl = 'https://itunes.apple.com/app/apple-store/id1620795451';
    res.render('index', { title: 'Fit With Friends', appStoreUrl });
});

router.get('/joinCompetition', function (req, res) {
    // All incoming query params are lowercased
    const competitionID = req.query['competitionid'];
    const competitionToken = req.query['competitiontoken'];

    if (!competitionID || !competitionToken) {
        handleError(null, 400, 'Missing required query param', res, true);
        return;
    }

    const ua = UAParser(req.headers['user-agent'] ?? '');
    const os = ua.os.name ?? '';
    // iPadOS 13+ reports the same UA as macOS, so treat Mac as potentially iOS
    const isIOS = os === 'iOS' || os === 'macOS';

const appStoreUrl = 'itms-apps://itunes.apple.com/app/apple-store/id1620795451';
    const appDeeplink = 'fitwithfriends://joinCompetition?competitionToken=' + competitionToken + '&competitionId=' + competitionID;

    res.render('joinCompetition', {
        title: 'Fit With Friends',
        isIOS: isIOS,
        appStoreUrl: appStoreUrl,
        appDeeplink: appDeeplink
    });
});

export default router;