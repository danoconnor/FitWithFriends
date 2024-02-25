'use strict';
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var errorHelpers_1 = __importDefault(require("../utilities/errorHelpers"));
var express_1 = __importDefault(require("express"));
var router = express_1.default.Router();
/* GET home page. */
router.get('/', function (req, res) {
    res.render('index', { title: 'Fit With Friends' });
});
// TODO: should we show an error/warning if the user agent isn't for iOS?
// For now we'll just assume that this page is running on an iOS device
router.get('/joinCompetition', function (req, res) {
    // All incoming query params are lowercased
    var competitionID = req.query['competitionid'];
    var competitionToken = req.query['competitiontoken'];
    if (!competitionID || !competitionToken) {
        (0, errorHelpers_1.default)(null, 400, 'Missing required query param', res, true);
        return;
    }
    // TODO: Need the actual app store ID
    var appStoreUrl = 'itms-apps://itunes.apple.com/app/apple-store/id983156458';
    var appDeeplink = 'fitwithfriends://joinCompetition?competitionToken=' + competitionToken + '&competitionId=' + competitionID;
    res.render('joinCompetition', {
        title: 'Fit With Friends',
        appStoreUrl: appStoreUrl,
        appDeeplink: appDeeplink
    });
});
exports.default = router;
