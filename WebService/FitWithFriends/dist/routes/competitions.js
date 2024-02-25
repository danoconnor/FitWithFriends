'use strict';
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var express = require("express");
var router = express.Router();
var cryptoHelpers = __importStar(require("../utilities/cryptoHelpers"));
var errorHelpers_1 = require("../utilities/errorHelpers");
var database_1 = require("../utilities/database");
var uuid_1 = require("uuid");
var FWFErrorCodes_1 = __importDefault(require("../utilities/FWFErrorCodes"));
var ActivitySummariesQueries = __importStar(require("../sql/activitySummaries.queries"));
var CompetitionQueries = __importStar(require("../sql/competitions.queries"));
var UserQueries = __importStar(require("../sql/users.queries"));
var userHelpers_1 = require("../utilities/userHelpers");
var msPerDay = 1000 * 60 * 60 * 24;
// We won't announce results until 24hrs after the competition ends
// This gives time for all clients to report final data and allows different timezones to complete their days
var competitionResultProcessingTimeMs = msPerDay * 1;
// Returns the competitionIds that the currently authenticated user is a member of
router.get('/', function (req, res) {
    CompetitionQueries.getUsersCompetitions.run({ userId: (0, userHelpers_1.convertUserIdToBuffer)(res.locals.oauth.token.user.id) }, database_1.DatabaseConnectionPool)
        .then(function (result) {
        var competitionIds = result.map(function (obj) { return obj.competition_id; });
        res.json(competitionIds);
    })
        .catch(function (error) {
        (0, errorHelpers_1.handleError)(error, 500, 'Error getting users competitions', res);
    });
});
// Create new competition. The currently authenticated user will become the admin for the competition.
// The request should have startDate, endDate, displayName, and timezone values
router.post('/', function (req, res) {
    var startDate = new Date(req.body['startDate']);
    var endDate = new Date(req.body['endDate']);
    var displayName = req.body['displayName'];
    var timezone = req.body['ianaTimezone'];
    if (!startDate || !endDate || !displayName || !timezone) {
        (0, errorHelpers_1.handleError)(null, 400, 'Missing required parameter', res);
        return;
    }
    // Validate competition length - must be between one and 30 days
    var maxCompetitionLengthInDays = 30;
    var maxCompetitionLengthInMs = maxCompetitionLengthInDays * msPerDay;
    var competitionLengthInMs = endDate.getTime() - startDate.getTime();
    if (competitionLengthInMs < msPerDay || competitionLengthInMs > maxCompetitionLengthInMs) {
        (0, errorHelpers_1.handleError)(null, 400, 'End date was not valid', res, true);
        return;
    }
    // Check that the timezone is valid so we don't blow up later
    if (!allIANATimezones.includes(timezone)) {
        (0, errorHelpers_1.handleError)(null, 400, 'Timezone "' + timezone + '" is not in list of valid timezones', res, true);
        return;
    }
    var startDateUTC = new Date(startDate.toUTCString());
    var endDateUTC = new Date(endDate.toUTCString());
    // Check that the user is allowed to join a new competition
    var userId = res.locals.oauth.token.user.id;
    validateCompetitionCountLimit(userId)
        .then(function () {
        // Generate an access code for this competition so users can be added
        var accessToken = cryptoHelpers.getRandomToken();
        var competitionId = (0, uuid_1.v4)();
        CompetitionQueries.createCompetition.run({ startDate: startDateUTC, endDate: endDateUTC, displayName: displayName, adminUserId: (0, userHelpers_1.convertUserIdToBuffer)(userId), accessToken: accessToken, ianaTimezone: timezone, competitionId: competitionId }, database_1.DatabaseConnectionPool)
            .then(function (_result) {
            // Add the admin user to the competition
            CompetitionQueries.addUserToCompetition.run({ userId: (0, userHelpers_1.convertUserIdToBuffer)(userId), competitionId: competitionId }, database_1.DatabaseConnectionPool)
                .then(function (_result) {
                res.json({
                    'competition_id': competitionId,
                    'accessCode': accessToken
                });
            })
                .catch(function (error) {
                (0, errorHelpers_1.handleError)(error, 500, 'Error adding user to new competition', res);
            });
        })
            .catch(function (error) {
            (0, errorHelpers_1.handleError)(error, 500, 'Error creating competition', res);
        });
    })
        .catch(function (error) {
        (0, errorHelpers_1.handleError)(error, 400, 'User is not eligible to join a new competition', res, true, FWFErrorCodes_1.default.CompetitionErrorCodes.TooManyActiveCompetitions);
    });
});
// Join existing competition endpoint - adds the currently authenticated user to the competition that matches the given token
// Expects a competition ID and competition access token in the request body
router.post('/join', function (req, res) {
    var accessToken = req.body['accessToken'];
    var competitionId = req.body['competitionId'];
    if (!accessToken || !competitionId) {
        (0, errorHelpers_1.handleError)(null, 400, 'Missing required param', res);
        return;
    }
    var userId = res.locals.oauth.token.user.id;
    // Find matching competition and validate access token
    CompetitionQueries.getCompetitionDescriptionDetails.run({ competitionAccessToken: accessToken, competitionId: competitionId }, database_1.DatabaseConnectionPool)
        .then(function (result) {
        if (!result.length) {
            errorHelpers.handleError(null, 404, 'Error finding competition', res);
            return;
        }
        // Check if the user has already hit their max number of active competitions
        var userId = res.locals.oauth.token.user.id;
        validateCompetitionCountLimit(userId).then(function () {
            // User is allowed to join a competition - add the user to the competition
            CompetitionQueries.addUserToCompetition.run({ userId: (0, userHelpers_1.convertUserIdToBuffer)(userId), competitionId: competitionId }, database_1.DatabaseConnectionPool)
                .then(function (_result) {
                res.sendStatus(200);
            })
                .catch(function (error) {
                (0, errorHelpers_1.handleError)(error, 500, 'Error adding user to competition', res);
            });
        })
            .catch(function (error) {
            (0, errorHelpers_1.handleError)(error, 400, 'User is not able to join competition', res, true, FWFErrorCodes_1.default.CompetitionErrorCodes.TooManyActiveCompetitions);
        });
    })
        .catch(function (error) {
        (0, errorHelpers_1.handleError)(error, 500, 'Error finding competition', res);
    });
});
// Leave competition endpoint
// Expects a userId and a competitionId in the request body
// The user will be removed from the competition if the currently authenticated user matches the user to remove
// OR the currently authenticated user is the admin of the competition
router.post('/leave', function (req, res) {
    var targetUserId = req.body['userId'];
    var competitionId = req.body['competitionId'];
    if (!targetUserId || !competitionId) {
        errorHelpers.handleError(null, 404, 'Missing required param', res);
        return;
    }
    if (targetUserId === res.locals.oauth.token.user.id) {
        selfRemoveUser(res, targetUserId, competitionId);
    }
    else {
        // This func will validate that the current user is the admin of the competition
        adminRemoveUser(res, targetUserId, competitionId);
    }
});
// Returns an overview of the given competition that contains a list of users and their current points for the competition
// The user must be a member of this competition in order to receive the data
//
// Expects a query param with the user's current timezone (to decide whether to show the competition as active or not)
router.get('/:competitionId/overview', function (req, res) {
    var _a;
    var timezoneParam = (_a = req.query['timezone']) === null || _a === void 0 ? void 0 : _a.toString();
    var competitionId = req.params.competitionId;
    if (!timezoneParam || !allIANATimezones.includes(timezoneParam)) {
        (0, errorHelpers_1.handleError)(null, 400, 'Invalid timezone query param', res);
        return;
    }
    // 1. Get the competition data and the users
    var userId = res.locals.oauth.token.user.id;
    Promise.all([
        UserQueries.getUsersInCompetition.run({ competitionId: competitionId }, database_1.DatabaseConnectionPool),
        CompetitionQueries.getCompetition.run({ competitionId: competitionId }, database_1.DatabaseConnectionPool)
    ])
        .then(function (_a) {
        var usersCompetitionsResult = _a[0], competitionsResult = _a[1];
        if (!usersCompetitionsResult.length || !competitionsResult.length) {
            (0, errorHelpers_1.handleError)(null, 404, 'Could not find competition info', res);
            return;
        }
        // 2. Check that the authenticated user is one of the members of this competition
        if (!usersCompetitionsResult.filter(function (row) { return row.userId === userId; }).length) {
            (0, errorHelpers_1.handleError)(null, 401, 'User is not a member of the competition', res);
            return;
        }
        // 3. Calculate points for the activity data for all of the users in the competition in the competition date range
        var competitionInfo = competitionsResult[0];
        var isUserAdmin = userId === (0, userHelpers_1.convertBufferToUserId)(competitionInfo.admin_user_id);
        // Make sure we use the date that matches the competition timezone
        var currentDateStr = new Date().toLocaleDateString('en-US', { timeZone: timezoneParam });
        var currentDate = new Date(currentDateStr);
        ;
        var userPoints = {};
        usersCompetitionsResult.forEach(function (row) {
            userPoints[row.userId] = {
                userId: row.userId,
                firstName: row.first_name,
                lastName: row.last_name,
                activityPoints: 0,
                pointsToday: 0
            };
        });
        var userIdList = usersCompetitionsResult.map(function (row) { return (0, userHelpers_1.convertUserIdToBuffer)(row.userId); });
        ActivitySummariesQueries.getActivitySummariesForUsers.run({ userIds: userIdList, startDate: competitionInfo.start_date, endDate: competitionInfo.end_date }, database_1.DatabaseConnectionPool)
            .then(function (activitySummaries) {
            // We allow users to score up to 600 total points per day (matching Apple's activity ring competition rules)
            // This will eventually change when we allow users to define custom scoring rules, but for now we will stick with Apple's rules
            var maxPointsPerDay = 600;
            activitySummaries.forEach(function (row) {
                var points = Math.round(row.calories_burned / row.calories_goal * 100) + Math.round(row.exercise_time / row.exercise_time_goal * 100) + Math.round(row.stand_time / row.stand_time_goal * 100);
                var pointsScoredThisDay = Math.min(points, maxPointsPerDay);
                userPoints[row.userId].activityPoints += pointsScoredThisDay;
                if (row.date.getDay() === currentDate.getDay() && row.date.getMonth() === currentDate.getMonth() && row.date.getFullYear() === currentDate.getFullYear()) {
                    userPoints[row.userId].pointsToday = pointsScoredThisDay;
                }
            });
            // We don't announce results until 24hrs after the competition has ended
            // This allows clients to report fina_i data and users in different timezones to finish their days
            var now = new Date();
            var timeSinceCompetitionEnd = now.getTime() - competitionInfo.end_date.getTime();
            var isCompetitionProcessingResults = timeSinceCompetitionEnd > 0 && timeSinceCompetitionEnd < competitionResultProcessingTimeMs;
            res.json({
                'competitionId': competitionInfo.competition_id,
                'competitionName': competitionInfo.display_name,
                'competitionStart': competitionInfo.start_date,
                'competitionEnd': competitionInfo.end_date,
                'isCompetitionProcessingResults': isCompetitionProcessingResults,
                'isUserAdmin': isUserAdmin,
                'currentResults': userPoints
            });
        })
            .catch(function (error) {
            (0, errorHelpers_1.handleError)(error, 500, 'Error calculating results', res);
        });
    })
        .catch(function (error) {
        (0, errorHelpers_1.handleError)(error, 500, 'Error getting competition info', res);
    });
});
// Returns a description of the competition containing the name, dates, and number of members of the competition
// The user does not need to be a member of the competition to get this info but they do need to have the competition access token
// Expects a competitionId and competitionAccessToken in the request body
router.post('/description', function (req, res) {
    var competitionId = req.body['competitionId'];
    var competitionToken = req.body['competitionAccessToken'];
    if (!competitionId || !competitionToken) {
        (0, errorHelpers_1.handleError)(null, 400, 'Missing required param', res);
        return;
    }
    Promise.all([
        CompetitionQueries.getNumUsersInCompetition.run({ competitionId: competitionId }, database_1.DatabaseConnectionPool),
        CompetitionQueries.getCompetitionDescriptionDetails.run({ competitionId: competitionId, competitionAccessToken: competitionToken }, database_1.DatabaseConnectionPool)
    ])
        .then(function (_a) {
        var usersCompetitionsResult = _a[0], competitionsResult = _a[1];
        if (!usersCompetitionsResult.length || !competitionsResult.length) {
            (0, errorHelpers_1.handleError)(null, 404, 'Could not find competition info', res);
            return;
        }
        var competitionInfo = competitionsResult[0];
        var numMembers = usersCompetitionsResult[0].count;
        // Find the display name of the competition admin so we can include it in the response
        // Don't need to use \x with admin_user_id because it comes from the previous query and is already in hex format
        UserQueries.getUserName.run({ userId: competitionInfo.admin_user_id }, database_1.DatabaseConnectionPool)
            .then(function (adminNameResult) {
            if (!adminNameResult.length) {
                (0, errorHelpers_1.handleError)(null, 500, 'Unexpected failure when looking up admin user info', res);
                return;
            }
            var adminName = adminNameResult[0].first_name + ' ' + adminNameResult[0].last_name;
            res.json({
                'competitionName': competitionInfo.display_name,
                'competitionStart': competitionInfo.start_date,
                'competitionEnd': competitionInfo.end_date,
                'numMembers': numMembers,
                'adminName': adminName
            });
        })
            .catch(function (error) {
            (0, errorHelpers_1.handleError)(error, 500, 'Error getting admin user details', res);
        });
    })
        .catch(function (error) {
        (0, errorHelpers_1.handleError)(error, 500, 'Error getting description for competition', res);
    });
});
// Returns the competition access token for the given competition ID
// The authenticated user must be the admin of the competition to receive this data
router.get('/:competitionId/adminDetail', function (req, res) {
    var competitionId = req.params.competitionId;
    var userId = res.locals.oauth.token.user.id;
    CompetitionQueries.getCompetitionAdminDetails.run({ competitionId: competitionId, adminUserId: (0, userHelpers_1.convertUserIdToBuffer)(userId) }, database_1.DatabaseConnectionPool)
        .then(function (result) {
        if (!result.length) {
            (0, errorHelpers_1.handleError)(null, 401, 'Competition not found or user is not admin', res);
            return;
        }
        var competitionInfo = result[0];
        res.json({
            'competitionAccessToken': competitionInfo.access_token,
            'competitionId': competitionInfo.competition_id
        });
    })
        .catch(function (error) {
        (0, errorHelpers_1.handleError)(error, 500, 'Error getting competition admin info', res);
    });
});
// Deletes the given competition
// The authenticated user must the admin of the competition to perform this action
// The request body should have the competitionId to delete
router.post('/delete', function (req, res) {
    var competitionId = req.body['competitionId'];
    if (!competitionId) {
        (0, errorHelpers_1.handleError)(null, 400, 'Missing required parameter competitionId', res);
        return;
    }
    // Confirm that the authenticated user is the admin
    var userId = res.locals.oauth.token.user.id;
    CompetitionQueries.getCompetitionAdminDetails.run({ competitionId: competitionId, adminUserId: (0, userHelpers_1.convertUserIdToBuffer)(userId) }, database_1.DatabaseConnectionPool)
        .then(function (result) {
        if (!result.length) {
            (0, errorHelpers_1.handleError)(null, 401, 'Competition not found or user is not admin', res);
            return;
        }
        CompetitionQueries.deleteCompetition.run({ competitionId: competitionId }, database_1.DatabaseConnectionPool)
            .then(function (_result) {
            res.sendStatus(200);
        })
            .catch(function (error) {
            (0, errorHelpers_1.handleError)(error, 500, 'Error deleting competition', res);
        });
    })
        .catch(function (error) {
        (0, errorHelpers_1.handleError)(error, 500, 'Error getting competition admin info', res);
    });
});
module.exports = router;
// Helper functions
// Called when the admin of the competition is removing another user from the competition
function adminRemoveUser(res, targetUserId, competitionId) {
    // Need to check that the current user is the admin of the competition
    var authenticatedUserId = res.locals.oauth.token.user.id;
    CompetitionQueries.getCompetitionAdminDetails.run({ competitionId: competitionId, adminUserId: (0, userHelpers_1.convertUserIdToBuffer)(authenticatedUserId) }, database_1.DatabaseConnectionPool)
        .then(function (adminDetailsResult) {
        if (!adminDetailsResult.length) {
            (0, errorHelpers_1.handleError)(null, 401, 'User is trying to remove someone other than self and is not admin', res);
            return;
        }
        CompetitionQueries.deleteUserFromCompetition.run({ userId: (0, userHelpers_1.convertUserIdToBuffer)(targetUserId), competitionId: competitionId }, database_1.DatabaseConnectionPool)
            .then(function (_deleteResult) {
            // Once the user is deleted, we need to change the competition access token so the removed user can't automatically re-join
            var newAccessToken = cryptoHelpers.getRandomToken();
            CompetitionQueries.updateCompetitionAccessToken.run({ competitionId: competitionId, newAccessToken: newAccessToken }, database_1.DatabaseConnectionPool)
                .then(function (_updateResult) {
                res.sendStatus(200);
            })
                .catch(function (error) {
                (0, errorHelpers_1.handleError)(error, 500, 'Failed to update competition token after removing user', res);
            });
        })
            .catch(function (error) {
            (0, errorHelpers_1.handleError)(error, 500, 'Error deleting user from competition as admin', res);
        });
    })
        .catch(function (error) {
        (0, errorHelpers_1.handleError)(error, 500, 'Error getting competition info', res);
    });
}
// Called when a user is trying to remove theirself from the competition
function selfRemoveUser(res, targetUserId, competitionId) {
    var authenticatedUserId = res.locals.oauth.token.user.id;
    if (targetUserId !== authenticatedUserId) {
        errorHelpers.handleError(null, 401, 'User is trying to remove someone other than self', res);
        return;
    }
    CompetitionQueries.deleteUserFromCompetition.run({ userId: (0, userHelpers_1.convertUserIdToBuffer)(authenticatedUserId), competitionId: competitionId }, database_1.DatabaseConnectionPool)
        .then(function (_result) {
        res.sendStatus(200);
    })
        .catch(function (error) {
        (0, errorHelpers_1.handleError)(error, 500, 'Error with user removing self from competition', res);
    });
}
// Checks that the user is under the max number of allowed active competitions
// Returns a Promise that will continue if the user user is allowed to join a new competition
// If the user cannot join a competition, then an error will be thrown
// Expects a hex-formated user ID as a parameter
function validateCompetitionCountLimit(userId) {
    // TODO: handle timezones for active competition count
    var currentDate = new Date();
    var userIdBuffer = (0, userHelpers_1.convertUserIdToBuffer)(userId);
    // Check if the user has already hit their max number of active competitions
    return new Promise(function (resolve, reject) {
        Promise.all([
            UserQueries.getUserMaxCompetitions.run({ userId: userIdBuffer }, database_1.DatabaseConnectionPool),
            CompetitionQueries.getNumberOfActiveCompetitionsForUser.run({ userId: userIdBuffer, currentDate: currentDate }, database_1.DatabaseConnectionPool)
        ]).then(function (_a) {
            var maxCompetitionResult = _a[0], competitionCountResult = _a[1];
            if (!maxCompetitionResult.length || !competitionCountResult) {
                reject(new Error('Failed to query competition limit info'));
                return;
            }
            var maxAllowedCompetitions = maxCompetitionResult[0].max_active_competitions;
            var currentCompetitionCount = competitionCountResult[0].count;
            if (currentCompetitionCount >= maxAllowedCompetitions) {
                reject(new Error('Too many active or upcoming competitions'));
                return;
            }
            resolve();
        }).catch(function (error) {
            reject(error);
        });
    });
}
// A list of all valid IANA timezone names
// From https://stackoverflow.com/questions/38399465/how-to-get-list-of-all-timezones-in-javascript
var allIANATimezones = [
    'Europe/Andorra',
    'Asia/Dubai',
    'Asia/Kabul',
    'Europe/Tirane',
    'Asia/Yerevan',
    'Antarctica/Casey',
    'Antarctica/Davis',
    'Antarctica/DumontDUrville',
    'Antarctica/Mawson',
    'Antarctica/Palmer',
    'Antarctica/Rothera',
    'Antarctica/Syowa',
    'Antarctica/Troll',
    'Antarctica/Vostok',
    'America/Argentina/Buenos_Aires',
    'America/Argentina/Cordoba',
    'America/Argentina/Salta',
    'America/Argentina/Jujuy',
    'America/Argentina/Tucuman',
    'America/Argentina/Catamarca',
    'America/Argentina/La_Rioja',
    'America/Argentina/San_Juan',
    'America/Argentina/Mendoza',
    'America/Argentina/San_Luis',
    'America/Argentina/Rio_Gallegos',
    'America/Argentina/Ushuaia',
    'Pacific/Pago_Pago',
    'Europe/Vienna',
    'Australia/Lord_Howe',
    'Antarctica/Macquarie',
    'Australia/Hobart',
    'Australia/Currie',
    'Australia/Melbourne',
    'Australia/Sydney',
    'Australia/Broken_Hill',
    'Australia/Brisbane',
    'Australia/Lindeman',
    'Australia/Adelaide',
    'Australia/Darwin',
    'Australia/Perth',
    'Australia/Eucla',
    'Asia/Baku',
    'America/Barbados',
    'Asia/Dhaka',
    'Europe/Brussels',
    'Europe/Sofia',
    'Atlantic/Bermuda',
    'Asia/Brunei',
    'America/La_Paz',
    'America/Noronha',
    'America/Belem',
    'America/Fortaleza',
    'America/Recife',
    'America/Araguaina',
    'America/Maceio',
    'America/Bahia',
    'America/Sao_Paulo',
    'America/Campo_Grande',
    'America/Cuiaba',
    'America/Santarem',
    'America/Porto_Velho',
    'America/Boa_Vista',
    'America/Manaus',
    'America/Eirunepe',
    'America/Rio_Branco',
    'America/Nassau',
    'Asia/Thimphu',
    'Europe/Minsk',
    'America/Belize',
    'America/St_Johns',
    'America/Halifax',
    'America/Glace_Bay',
    'America/Moncton',
    'America/Goose_Bay',
    'America/Blanc-Sablon',
    'America/Toronto',
    'America/Nipigon',
    'America/Thunder_Bay',
    'America/Iqaluit',
    'America/Pangnirtung',
    'America/Atikokan',
    'America/Winnipeg',
    'America/Rainy_River',
    'America/Resolute',
    'America/Rankin_Inlet',
    'America/Regina',
    'America/Swift_Current',
    'America/Edmonton',
    'America/Cambridge_Bay',
    'America/Yellowknife',
    'America/Inuvik',
    'America/Creston',
    'America/Dawson_Creek',
    'America/Fort_Nelson',
    'America/Vancouver',
    'America/Whitehorse',
    'America/Dawson',
    'Indian/Cocos',
    'Europe/Zurich',
    'Africa/Abidjan',
    'Pacific/Rarotonga',
    'America/Santiago',
    'America/Punta_Arenas',
    'Pacific/Easter',
    'Asia/Shanghai',
    'Asia/Urumqi',
    'America/Bogota',
    'America/Costa_Rica',
    'America/Havana',
    'Atlantic/Cape_Verde',
    'America/Curacao',
    'Indian/Christmas',
    'Asia/Nicosia',
    'Asia/Famagusta',
    'Europe/Prague',
    'Europe/Berlin',
    'Europe/Copenhagen',
    'America/Santo_Domingo',
    'Africa/Algiers',
    'America/Guayaquil',
    'Pacific/Galapagos',
    'Europe/Tallinn',
    'Africa/Cairo',
    'Africa/El_Aaiun',
    'Europe/Madrid',
    'Africa/Ceuta',
    'Atlantic/Canary',
    'Europe/Helsinki',
    'Pacific/Fiji',
    'Atlantic/Stanley',
    'Pacific/Chuuk',
    'Pacific/Pohnpei',
    'Pacific/Kosrae',
    'Atlantic/Faroe',
    'Europe/Paris',
    'Europe/London',
    'Asia/Tbilisi',
    'America/Cayenne',
    'Africa/Accra',
    'Europe/Gibraltar',
    'America/Godthab',
    'America/Danmarkshavn',
    'America/Scoresbysund',
    'America/Thule',
    'Europe/Athens',
    'Atlantic/South_Georgia',
    'America/Guatemala',
    'Pacific/Guam',
    'Africa/Bissau',
    'America/Guyana',
    'Asia/Hong_Kong',
    'America/Tegucigalpa',
    'America/Port-au-Prince',
    'Europe/Budapest',
    'Asia/Jakarta',
    'Asia/Pontianak',
    'Asia/Makassar',
    'Asia/Jayapura',
    'Europe/Dublin',
    'Asia/Jerusalem',
    'Asia/Kolkata',
    'Indian/Chagos',
    'Asia/Baghdad',
    'Asia/Tehran',
    'Atlantic/Reykjavik',
    'Europe/Rome',
    'America/Jamaica',
    'Asia/Amman',
    'Asia/Tokyo',
    'Africa/Nairobi',
    'Asia/Bishkek',
    'Pacific/Tarawa',
    'Pacific/Enderbury',
    'Pacific/Kiritimati',
    'Asia/Pyongyang',
    'Asia/Seoul',
    'Asia/Almaty',
    'Asia/Qyzylorda',
    'Asia/Qostanay',
    'Asia/Aqtobe',
    'Asia/Aqtau',
    'Asia/Atyrau',
    'Asia/Oral',
    'Asia/Beirut',
    'Asia/Colombo',
    'Africa/Monrovia',
    'Europe/Vilnius',
    'Europe/Luxembourg',
    'Europe/Riga',
    'Africa/Tripoli',
    'Africa/Casablanca',
    'Europe/Monaco',
    'Europe/Chisinau',
    'Pacific/Majuro',
    'Pacific/Kwajalein',
    'Asia/Yangon',
    'Asia/Ulaanbaatar',
    'Asia/Hovd',
    'Asia/Choibalsan',
    'Asia/Macau',
    'America/Martinique',
    'Europe/Malta',
    'Indian/Mauritius',
    'Indian/Maldives',
    'America/Mexico_City',
    'America/Cancun',
    'America/Merida',
    'America/Monterrey',
    'America/Matamoros',
    'America/Mazatlan',
    'America/Chihuahua',
    'America/Ojinaga',
    'America/Hermosillo',
    'America/Tijuana',
    'America/Bahia_Banderas',
    'Asia/Kuala_Lumpur',
    'Asia/Kuching',
    'Africa/Maputo',
    'Africa/Windhoek',
    'Pacific/Noumea',
    'Pacific/Norfolk',
    'Africa/Lagos',
    'America/Managua',
    'Europe/Amsterdam',
    'Europe/Oslo',
    'Asia/Kathmandu',
    'Pacific/Nauru',
    'Pacific/Niue',
    'Pacific/Auckland',
    'Pacific/Chatham',
    'America/Panama',
    'America/Lima',
    'Pacific/Tahiti',
    'Pacific/Marquesas',
    'Pacific/Gambier',
    'Pacific/Port_Moresby',
    'Pacific/Bougainville',
    'Asia/Manila',
    'Asia/Karachi',
    'Europe/Warsaw',
    'America/Miquelon',
    'Pacific/Pitcairn',
    'America/Puerto_Rico',
    'Asia/Gaza',
    'Asia/Hebron',
    'Europe/Lisbon',
    'Atlantic/Madeira',
    'Atlantic/Azores',
    'Pacific/Palau',
    'America/Asuncion',
    'Asia/Qatar',
    'Indian/Reunion',
    'Europe/Bucharest',
    'Europe/Belgrade',
    'Europe/Kaliningrad',
    'Europe/Moscow',
    'Europe/Simferopol',
    'Europe/Kirov',
    'Europe/Astrakhan',
    'Europe/Volgograd',
    'Europe/Saratov',
    'Europe/Ulyanovsk',
    'Europe/Samara',
    'Asia/Yekaterinburg',
    'Asia/Omsk',
    'Asia/Novosibirsk',
    'Asia/Barnaul',
    'Asia/Tomsk',
    'Asia/Novokuznetsk',
    'Asia/Krasnoyarsk',
    'Asia/Irkutsk',
    'Asia/Chita',
    'Asia/Yakutsk',
    'Asia/Khandyga',
    'Asia/Vladivostok',
    'Asia/Ust-Nera',
    'Asia/Magadan',
    'Asia/Sakhalin',
    'Asia/Srednekolymsk',
    'Asia/Kamchatka',
    'Asia/Anadyr',
    'Asia/Riyadh',
    'Pacific/Guadalcanal',
    'Indian/Mahe',
    'Africa/Khartoum',
    'Europe/Stockholm',
    'Asia/Singapore',
    'America/Paramaribo',
    'Africa/Juba',
    'Africa/Sao_Tome',
    'America/El_Salvador',
    'Asia/Damascus',
    'America/Grand_Turk',
    'Africa/Ndjamena',
    'Indian/Kerguelen',
    'Asia/Bangkok',
    'Asia/Dushanbe',
    'Pacific/Fakaofo',
    'Asia/Dili',
    'Asia/Ashgabat',
    'Africa/Tunis',
    'Pacific/Tongatapu',
    'Europe/Istanbul',
    'America/Port_of_Spain',
    'Pacific/Funafuti',
    'Asia/Taipei',
    'Europe/Kiev',
    'Europe/Uzhgorod',
    'Europe/Zaporozhye',
    'Pacific/Wake',
    'America/New_York',
    'America/Detroit',
    'America/Kentucky/Louisville',
    'America/Kentucky/Monticello',
    'America/Indiana/Indianapolis',
    'America/Indiana/Vincennes',
    'America/Indiana/Winamac',
    'America/Indiana/Marengo',
    'America/Indiana/Petersburg',
    'America/Indiana/Vevay',
    'America/Chicago',
    'America/Indiana/Tell_City',
    'America/Indiana/Knox',
    'America/Menominee',
    'America/North_Dakota/Center',
    'America/North_Dakota/New_Salem',
    'America/North_Dakota/Beulah',
    'America/Denver',
    'America/Boise',
    'America/Phoenix',
    'America/Los_Angeles',
    'America/Anchorage',
    'America/Juneau',
    'America/Sitka',
    'America/Metlakatla',
    'America/Yakutat',
    'America/Nome',
    'America/Adak',
    'Pacific/Honolulu',
    'America/Montevideo',
    'Asia/Samarkand',
    'Asia/Tashkent',
    'America/Caracas',
    'Asia/Ho_Chi_Minh',
    'Pacific/Efate',
    'Pacific/Wallis',
    'Pacific/Apia',
    'Africa/Johannesburg'
];
