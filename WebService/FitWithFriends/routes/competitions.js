'use strict';

const express = require('express');
const router = express.Router();
const database = require('../utilities/database');
const errorHelpers = require('../utilities/errorHelpers');
const cryptoHelpers = require('../utilities/cryptoHelpers');
const { v4: uuid } = require('uuid');
const FWFErrorCodes = require('../utilities/FWFErrorCodes');

// Returns the competitionIds that the currently authenticated user is a member of
router.get('/', function (req, res) {
    database.query('SELECT competition_id from users_competitions WHERE user_id = $1', ['\\x' + res.locals.oauth.token.user.id])
        .then(function (result) {

            const competitionIds = result.map(obj => obj.competition_id);
            res.json(competitionIds);
        })
        .catch(function (error) {
            errorHelpers.handleError(error, 500, 'Error getting users competitions', res);
        });
});

// Create new competition. The currently authenticated user will become the admin for the competition.
// The request should have startDate, endDate, displayName, and timezone values
router.post('/', function (req, res) {
    const startDate = new Date(req.body['startDate']);
    const endDate = new Date(req.body['endDate']);
    const displayName = req.body['displayName'];
    const timezone = req.body['ianaTimezone'];

    // Prefix the value with \x so the database will treat it as a hex value
    const userId = res.locals.oauth.token.user.id;
    const sqlHexUserId = '\\x' + userId;

    if (!startDate || !endDate || !displayName || !timezone) {
        errorHelpers.handleError(null, 400, 'Missing required parameter', res);
        return;
    }

    // Validate competition length - must be between one and 30 days
    const maxCompetitionLengthInDays = 30;
    const msPerDay = 1000 * 60 * 60 * 24;
    const maxCompetitionLengthInMs = maxCompetitionLengthInDays * msPerDay;
    const competitionLengthInMs = endDate.getTime() - startDate.getTime();
    if (competitionLengthInMs < msPerDay || competitionLengthInMs > maxCompetitionLengthInMs) {
        errorHelpers.handleError(null, 400, 'End date was not valid', res);
        return;
    }

    // Check that the timezone is valid so we don't blow up later
    if (!allIANATimezones.includes(timezone)) {
        errorHelpers.handleError(null, 400, 'Timezone "' + timezone + '" is not in list of valid timezones', res);
        return;
    }

    // Check that the user is allowed to join a new competition
    validateCompetitionCountLimit(sqlHexUserId)
        .then(function () {
            // Generate an access code for this competition so users can be added
            const accessToken = cryptoHelpers.getRandomToken();

            const competitionId = uuid();
            database.query('INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id) VALUES ($1, $2, $3, $4, $5, $6, $7)',
                [startDate, endDate, displayName, sqlHexUserId, accessToken, timezone, competitionId])
                .then(function (result) {
                    // Add the admin user to the competition
                    database.query('INSERT INTO users_competitions VALUES ($1, $2)', [sqlHexUserId, competitionId])
                        .then(function (result) {
                            res.json({
                                'competition_id': competitionId,
                                'accessCode': accessToken
                            });
                        })
                        .catch(function (error) {
                            errorHelpers.handleError(error, 500, 'Error adding user to new competition', res);
                        });
                })
                .catch(function (error) {
                    errorHelpers.handleError(error, 500, 'Error creating competition', res);
                });
        })
        .catch(function (error) {
            errorHelpers.handleError(error, 400, 'User is not eligible to join a new competition', res, true, FWFErrorCodes.TooManyActiveCompetitions);
        });
});

// Join existing competition endpoint - adds the currently authenticated user to the competition that matches the given token
// Expects a competition ID and competition access token in the request body
router.post('/join', function (req, res) {
    const accessToken = req.body['accessToken'];
    const competitionId = req.body['competitionId'];
    if (!accessToken || !competitionId) {
        errorHelpers.handleError(null, 400, 'Missing required param', res);
        return;
    }

    // Prefix the value with \x so the database will treat it as a hex value
    const userId = res.locals.oauth.token.user.id;
    const sqlHexUserId = '\\x' + userId;

    // Find matching competition and validate access token
    database.query('SELECT competition_id, iana_timezone FROM competitions WHERE access_token = $1 AND competition_id = $2', [accessToken, competitionId])
        .then(function (result) {
            if (!result.length) {
                errorHelpers.handleError(null, 404, 'Error finding competition', res);
                return;
            }

            const competitionId = result[0].competition_id;

            // Check if the user has already hit their max number of active competitions
            validateCompetitionCountLimit(sqlHexUserId).then(function () {
                // User is allowed to join a competition - add the user to the competition
                database.query('INSERT INTO users_competitions VALUES ($1, $2) \
                        ON CONFLICT (user_id, competition_id) DO NOTHING', [sqlHexUserId, competitionId])
                    .then(function (result) {
                        res.sendStatus(200);
                    })
                    .catch(function (error) {
                        errorHelpers.handleError(error, 500, 'Error adding user to competition', res);
                    });
            })
            .catch(function (error) {
                errorHelpers.handleError(error, 400, 'User is not able to join competition', res, true, FWFErrorCodes.TooManyActiveCompetitions);
            });
        })
        .catch(function (error) {
            errorHelpers.handleError(error, 500, 'Error finding competition', res);
        });
});

// Leave competition endpoint
// Expects a userId and a competitionId in the request body
// The user will be removed from the competition if the currently authenticated user matches the user to remove
// OR the currently authenticated user is the admin of the competition
router.post('/leave', function (req, res) {
    const targetUserId = req.body['userId'];
    const competitionId = req.body['competitionId'];
    if (!targetUserId || !competitionId) {
        errorHelpers.handleError(null, 404, 'Missing required param', res);
        return;
    }

    if (targetUserId === res.locals.oauth.token.user.id) {
        selfRemoveUser(req, res, targetUserId, competitionId);
    } else {
        // This func will validate that the current user is the admin of the competition
        adminRemoveUser(req, res, targetUserId, competitionId);
    }
});

// Returns an overview of the given competition that contains a list of users and their current points for the competition
// The user must be a member of this competition in order to receive the data
router.get('/:competitionId/overview', function (req, res) {
    // 1. Get the competition data and the users
    Promise.all([
        database.query('SELECT user_id FROM users_competitions WHERE competition_id = $1', [req.params.competitionId]),
        database.query('SELECT competition_id, start_date, end_date, display_name, admin_user_id, iana_timezone FROM competitions WHERE competition_id = $1', [req.params.competitionId])
    ])
        .then(function (result) {
            if (result.length < 2) {
                errorHelpers.handleError(null, 500, 'Unexpected failure when getting competition info', res);
                return;
            }

            const usersCompetitionsResult = result[0];
            const competitionsResult = result[1];

            if (!usersCompetitionsResult.length || !competitionsResult.length) {
                errorHelpers.handleError(null, 404, 'Could not find competition info', res);
                return;
            }

            // 2. Check that the authenticated user is one of the members of this competition
            if (!usersCompetitionsResult.filter(function (row) { return Buffer.from(row.user_id).toString('hex') === res.locals.oauth.token.user.id }).length) {
                errorHelpers.handleError(null, 401, 'User is not a member of the competition', res);
                return;
            }

            // 3. Calculate points for the activity data for all of the users in the competition in the competition date range

            const userIdList = usersCompetitionsResult.map(row => '\'\\x' + Buffer.from(row.user_id).toString('hex') + '\'').join();
            const competitionInfo = competitionsResult[0];
            const isUserAdmin = res.locals.oauth.token.user.id === Buffer.from(competitionInfo.admin_user_id).toString('hex');

            var query = '';
            var queryParams = [];

            // Make sure we use the date that matches the competition timezone
            let currentDateStr = new Date().toLocaleDateString('en-US', { timeZone: competitionInfo.iana_timezone });
            let currentDate = new Date(currentDateStr);

            // If the competition is currently active, then include each user's activity points so far today in the results
            if (currentDate >= competitionInfo.start_date && currentDate <= competitionInfo.end_date) {
                queryParams = [competitionInfo.start_date, competitionInfo.end_date, currentDate];
                query = 'SELECT userInfo.user_id, first_name, last_name, activity_points, daily_points FROM \
                    (SELECT user_id, first_name, last_name FROM users WHERE user_id in (' + userIdList + ')) AS userInfo \
                    LEFT OUTER JOIN \
                        (SELECT user_id, SUM(daily_points) AS activity_points \
                        FROM activity_summaries \
                        WHERE date >= $1 and date <= $2 and user_id in (' + userIdList + ') \
                        GROUP BY user_id) AS activitySummaryData \
                        LEFT OUTER JOIN \
                            (SELECT user_id, daily_points \
                            FROM activity_summaries \
                            WHERE date = $3 and user_id in (' + userIdList + ')) AS today_points \
                            ON activitySummaryData.user_id = today_points.user_id \
                    ON activitySummaryData.user_id = userInfo.user_id';
            } else {
                queryParams = [competitionInfo.start_date, competitionInfo.end_date];
                query = 'SELECT userInfo.user_id, first_name, last_name, activity_points FROM \
                    (SELECT user_id, first_name, last_name FROM users WHERE user_id in (' + userIdList + ')) AS userInfo \
                    LEFT OUTER JOIN \
                        (SELECT user_id, SUM(daily_points) AS activity_points \
                        FROM activity_summaries \
                        WHERE date >= $1 and date <= $2 and user_id in (' + userIdList + ') \
                        GROUP BY user_id) AS activitySummaryData \
                    ON activitySummaryData.user_id = userInfo.user_id';
            }

            database.query(query, queryParams)
                .then(function (result) {
                    // Need to convert the binary user ID to a string to return to the client
                    const parsedResults = result.map(row => {
                        return {
                            user_id: Buffer.from(row.user_id).toString('hex'),
                            first_name: row.first_name,
                            last_name: row.last_name,
                            activity_points: row.activity_points,
                            daily_points: row.daily_points
                        }
                    })

                    res.json({
                        'competitionId': competitionInfo.competition_id,
                        'competitionName': competitionInfo.display_name,
                        'competitionStart': competitionInfo.start_date,
                        'competitionEnd': competitionInfo.end_date,
                        'isUserAdmin': isUserAdmin,
                        'currentResults': parsedResults
                    });
                })
                .catch(function (error) {
                    errorHelpers.handleError(error, 500, 'Error calculating results', res);
                });
        })
        .catch(function (error) {
            errorHelpers.handleError(error, 500, 'Error getting competition info', res);
        });
});

// Returns a description of the competition containing the name, dates, and number of members of the competition
// The user does not need to be a member of the competition to get this info but they do need to have the competition access token
// Expects a competitionId and competitionAccessToken in the request body
router.post('/description', function (req, res) {
    const competitionId = req.body['competitionId'];
    const competitionToken = req.body['competitionAccessToken'];

    if (!competitionId || !competitionToken) {
        errorHelpers.handleError(null, 400, 'Missing required param', res);
        return;
    }

    Promise.all([
        database.query('SELECT COUNT(user_id) FROM users_competitions WHERE competition_id = $1', [competitionId]),
        database.query('SELECT start_date, end_date, display_name, admin_user_id FROM competitions WHERE competition_id = $1 AND access_token = $2', [competitionId, competitionToken])
    ])
        .then(function (result) {
            if (result.length < 2) {
                errorHelpers.handleError(null, 500, 'Unexpected failure when getting competition info', res);
                return;
            }

            const usersCompetitionsResult = result[0];
            const competitionsResult = result[1];

            if (!usersCompetitionsResult.length || !competitionsResult.length) {
                errorHelpers.handleError(null, 404, 'Could not find competition info', res);
                return;
            }

            const competitionInfo = competitionsResult[0];
            const numMembers = usersCompetitionsResult[0].count;

            // Find the display name of the competition admin so we can include it in the response
            // Don't need to use \x with admin_user_id because it comes from the previous query and is already in hex format
            database.query('SELECT first_name, last_name FROM users WHERE user_id = $1', [competitionInfo.admin_user_id])
                .then(function (result) {
                    if (!result.length) {
                        errorHelpers.handleError(null, 500, 'Unexpected failure when looking up admin user info', res);
                        return;
                    }

                    const adminName = result[0].first_name + ' ' + result[0].last_name;

                    res.json({
                        'competitionName': competitionInfo.display_name,
                        'competitionStart': competitionInfo.start_date,
                        'competitionEnd': competitionInfo.end_date,
                        'numMembers': parseInt(numMembers),
                        'adminName': adminName
                    });
                })
                .catch(function (error) {
                    errorHelpers.handleError(error, 500, 'Error getting admin user details', res);
                });
        })
        .catch(function (error) {
            errorHelpers.handleError(error, 500, 'Error getting description for competition', res);
        });
});

// Returns the competition access token for the given competition ID
// The authenticated user must be the admin of the competition to receive this data
router.get('/:competitionId/adminDetail', function (req, res) {
    database.query('SELECT competition_id, access_token FROM competitions WHERE competition_id = $1 AND admin_user_id = $2', [req.params.competitionId, '\\x' + res.locals.oauth.token.user.id])
        .then(function (result) {
            if (!result.length) {
                errorHelpers.handleError(error, 401, 'Competition not found or user is not admin', res);
                return;
            }

            const competitionInfo = result[0];
            res.json({
                'competitionAccessToken': competitionInfo.access_token,
                'competitionId': competitionInfo.competition_id
            });
        })
        .catch(function (error) {
            errorHelpers.handleError(error, 500, 'Error getting competition admin info', res);
        });
});

// Deletes the given competition
// The authenticated user must the admin of the competition to perform this action
// The request body should have the competitionId to delete
router.post('/delete', function (req, res) {
    const competitionId = req.body['competitionId'];
    if (!competitionId) {
        errorHelpers.handleError(null, 400, 'Missing required parameter competitionId', res);
    }

    // Confirm that the authenticated user is the admin
    database.query('SELECT competition_id, access_token FROM competitions WHERE competition_id = $1 AND admin_user_id = $2', [competitionId, '\\x' + res.locals.oauth.token.user.id])
        .then(function (result) {
            if (!result.length) {
                errorHelpers.handleError(error, 401, 'Competition not found or user is not admin', res);
                return;
            }

            database.query('DELETE FROM competitions WHERE competition_id = $1', [competitionId])
                .then(function (result) {
                    res.sendStatus(200);
                })
                .catch(function (error) {
                    errorHelpers.handleError(error, 500, 'Error deleting competition', res);
                });
        })
        .catch(function (error) {
            errorHelpers.handleError(error, 500, 'Error getting competition admin info', res);
        });
});

module.exports = router;

// Helper functions

// Called when the admin of the competition is removing another user from the competition
function adminRemoveUser(req, res, targetUserId, competitionId) {
    const sqlHexTargetUserId = '\\x' + targetUserId;

    // Need to check that the current user is the admin of the competition
    database.query('SELECT COUNT(competition_id) FROM competitions WHERE admin_user_id = $1 AND competition_id = $2', ['\\x' + res.locals.oauth.token.user.id, competitionId])
        .then(function (result) {
            if (!result.length || result[0].count != 1) {
                errorHelpers.handleError(error, 401, 'User is trying to remove someone other than self and is not admin', res);
                return;
            }

            database.query('DELETE FROM users_competitions WHERE user_id = $1 AND competition_id = $2', [sqlHexTargetUserId, competitionId])
                .then(function (result) {
                    // Once the user is deleted, we need to change the competition access token so the removed user can't automatically re-join
                    const newAccessToken = cryptoHelpers.getRandomToken();
                    database.query('UPDATE competitions SET access_token = $1 WHERE competition_id = $2', [newAccessToken, competitionId])
                        .then(function (result) {
                            res.sendStatus(200);
                        })
                        .catch(function (error) {
                            errorHelpers.handleError(error, 500, 'Failed to update competition token after removing user', res);
                        });
                })
                .catch(function (error) {
                    errorHelpers.handleError(error, 500, 'Error deleting user from competition as admin', res);
                });
        })
        .catch(function (error) {
            errorHelpers.handleError(error, 500, 'Error getting competition info', res);
        });
}

// Called when a user is trying to remove theirself from the competition
function selfRemoveUser(req, res, targetUserId, competitionId) {
    if (targetUserId !== res.locals.oauth.token.user.id) {
        errorHelpers.handleError(error, 401, 'User is trying to remove someone other than self', res);
        return;
    }

    database.query('DELETE FROM users_competitions WHERE user_id = $1 AND competition_id = $2', ['\\x' + res.locals.oauth.token.user.id, competitionId])
        .then(function (result) {
            res.sendStatus(200);
        })
        .catch(function (error) {
            errorHelpers.handleError(error, 500, 'Error with user removing self from competition', res);
        });
}

// Checks that the user is under the max number of allowed active competitions
// Returns a Promise that will continue if the user user is allowed to join a new competition
// If the user cannot join a competition, then an error will be thrown
// Expects a hex-formated user ID as a parameter
function validateCompetitionCountLimit(sqlHexUserId) {
    // TODO: handle timezones for active competition count
    const currentDate = new Date();

    // Check if the user has already hit their max number of active competitions
    return new Promise((resolve, reject) => {
        Promise.all([
            database.query('SELECT max_active_competitions FROM users WHERE user_id = $1', [sqlHexUserId]),
            database.query('SELECT COUNT(competitionData.competition_id) FROM \
                                (SELECT competition_id FROM users_competitions WHERE user_id = $1) as usersCompetitions \
	                            INNER JOIN \
                                    (SELECT competition_id, end_date FROM competitions) as competitionData \
	                            ON usersCompetitions.competition_id = competitionData.competition_id \
	                        WHERE end_date > $2', [sqlHexUserId, currentDate])
        ]).then(function (results) {
            const maxCompetitionResult = results[0];
            const competitionCountResult = results[1];

            if (!maxCompetitionResult.length || !competitionCountResult) {
                reject(new Error('Failed to query competition limit info'));
                return;
            }

            const maxAllowedCompetitions = maxCompetitionResult[0].max_active_competitions;
            const currentCompetitionCount = competitionCountResult[0].count;

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
const allIANATimezones = [
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