'use strict';

import express = require('express');
const router = express.Router();
import * as cryptoHelpers from '../utilities/cryptoHelpers';
import { handleError } from '../utilities/errorHelpers';
import { v4 as uuid } from 'uuid';
import FWFErrorCodes from '../utilities/enums/FWFErrorCodes';
import * as ActivityDataQueries from '../sql/activityData.queries';
import * as CompetitionQueries from '../sql/competitions.queries';
import * as UserQueries from '../sql/users.queries';
import { convertBufferToUserId, convertUserIdToBuffer } from '../utilities/userHelpers';
import { getCompetitionStandings } from '../utilities/competitionStandingsHelper';

const msPerDay = 1000 * 60 * 60 * 24;

// We won't announce results until 24hrs after the competition ends
// This gives time for all clients to report final data and allows different timezones to complete their days
const competitionResultProcessingTimeMs = msPerDay * 1;

// Returns the competitionIds that the currently authenticated user is a member of
router.get('/', function (req, res) {
    CompetitionQueries.getUsersCompetitions({ userId: convertUserIdToBuffer(res.locals.oauth.token.user.id) })
        .then(result => {
            const competitionIds = result.map(obj => obj.competition_id);
            res.json(competitionIds);
        })
        .catch(error => {
            handleError(error, 500, 'Error getting users competitions', res);
        });
});

// Create new competition. The currently authenticated user will become the admin for the competition.
// The request should have startDate, endDate, displayName, and timezone values
router.post('/', function (req, res) {
    const startDate = new Date(req.body['startDate']);
    const endDate = new Date(req.body['endDate']);
    const displayName: string = req.body['displayName'];
    const timezone: string = req.body['ianaTimezone'];

    if (!startDate || !endDate || !displayName || !timezone) {
        handleError(null, 400, 'Missing required parameter', res);
        return;
    }

    if (displayName.length > 255) {
        handleError(null, 400, 'Display name is too long', res);
        return;
    }

    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
        handleError(null, 400, 'Invalid date format', res);
        return;
    }

    if (endDate < new Date()) {
        handleError(null, 400, 'End date must be in the future', res);
        return;
    }

    // Validate competition length - must be between one and 30 days
    const maxCompetitionLengthInDays = 30;
    const maxCompetitionLengthInMs = maxCompetitionLengthInDays * msPerDay;
    const competitionLengthInMs = endDate.getTime() - startDate.getTime();
    if (competitionLengthInMs < msPerDay || competitionLengthInMs > maxCompetitionLengthInMs) {
        handleError(null, 400, 'End date was not valid', res, true);
        return;
    }

    // Check that the timezone is valid so we don't blow up later
    if (!allIANATimezones.includes(timezone)) {
        handleError(null, 400, 'Timezone "' + timezone + '" is not in list of valid timezones', res, true);
        return;
    }

    const startDateUTC = new Date(startDate.toUTCString());
    const endDateUTC = new Date(endDate.toUTCString());

    // Check that the user is allowed to join a new competition
    const userId: string = res.locals.oauth.token.user.id;
    validateCompetitionCountLimit(userId)
        .then(function () {
            // Generate an access code for this competition so users can be added
            const accessToken = cryptoHelpers.getRandomToken();

            const competitionId = uuid();
            CompetitionQueries.createCompetition({ startDate: startDateUTC, endDate: endDateUTC, displayName, adminUserId: convertUserIdToBuffer(userId), accessToken, ianaTimezone: timezone, competitionId })
                .then((_result) => {
                    // Add the admin user to the competition
                    CompetitionQueries.addUserToCompetition({ userId: convertUserIdToBuffer(userId), competitionId })
                        .then(function (_result) {
                            res.json({
                                'competition_id': competitionId,
                                'accessCode': accessToken
                            });
                        })
                        .catch(error => {
                            handleError(error, 500, 'Error adding user to new competition', res);
                        });
                })
                .catch(error => {
                    handleError(error, 500, 'Error creating competition', res);
                });
        })
        .catch(error => {
            handleError(error, 400, 'User is not eligible to join a new competition', res, true, FWFErrorCodes.CompetitionErrorCodes.TooManyActiveCompetitions);
        });
});

// Join existing competition endpoint - adds the currently authenticated user to the competition that matches the given token
// Expects a competition ID and competition access token in the request body
router.post('/join', function (req, res) {
    const accessToken: string = req.body['accessToken'];
    const competitionId: string = req.body['competitionId'];
    if (!accessToken || !competitionId) {
        handleError(null, 400, 'Missing required param', res);
        return;
    }

    // Find matching competition and validate access token
    CompetitionQueries.getCompetitionDescriptionDetails({ competitionAccessToken: accessToken, competitionId })
        .then((result) => {
            if (!result.length) {
                handleError(null, 404, 'Error finding competition', res);
                return;
            }

            // Check if the user has already hit their max number of active competitions
            const userId: string = res.locals.oauth.token.user.id;
            validateCompetitionCountLimit(userId).then(function () {
                // User is allowed to join a competition - add the user to the competition
                CompetitionQueries.addUserToCompetition({ userId: convertUserIdToBuffer(userId), competitionId })
                    .then((_result) => {
                        res.sendStatus(200);
                    })
                    .catch((error) => {
                        handleError(error, 500, 'Error adding user to competition', res);
                    });
            })
            .catch((error) => {
                handleError(error, 400, 'User is not able to join competition', res, true, FWFErrorCodes.CompetitionErrorCodes.TooManyActiveCompetitions);
            });
        })
        .catch((error) => {
            handleError(error, 500, 'Error finding competition', res);
        });
});

// Leave competition endpoint
// Expects a userId and a competitionId in the request body
// The user will be removed from the competition if the currently authenticated user matches the user to remove
// OR the currently authenticated user is the admin of the competition
router.post('/leave', function (req, res) {
    const targetUserId: string = req.body['userId'];
    const competitionId: string = req.body['competitionId'];
    if (!targetUserId || !competitionId) {
        handleError(null, 400, 'Missing required param', res);
        return;
    }

    // Get the admin user ID for the competition
    CompetitionQueries.getCompetition({ competitionId })
        .then(competitionResult => {
            if (!competitionResult.length) {
                handleError(null, 404, 'Could not find competition info', res);
                return;
            }

            const adminUserId = convertBufferToUserId(competitionResult[0].admin_user_id);
            if (targetUserId === adminUserId) {
                // If the admin user leaves the competition then nobody has the power
                // to add new users or delete the competition
                // So we do not allow the admin to leave the competition (they must delete the competition instead)
                handleError(null, 400, 'Admin user cannot leave competition', res);
                return;
            }

            const authenticatedUserId = res.locals.oauth.token.user.id;
            const isUserAdmin = authenticatedUserId === adminUserId;
            const isUserSelf = authenticatedUserId === targetUserId;
            
            // Admins can remove anyone, but normal users can only remove themselves
            const canRemoveTargetUser = isUserAdmin || isUserSelf;
            if (!canRemoveTargetUser) {
                handleError(null, 401, 'User is not authorized to remove target user', res);
                return;
            }

            CompetitionQueries.deleteUserFromCompetition({ userId: convertUserIdToBuffer(targetUserId), competitionId })
                .then(_result => {
                    if (isUserSelf) {
                        res.sendStatus(200);
                        return;
                    }

                    // If the admin removed another user, then we need to change the competition access token
                    // so the removed user cannot rejoin the competition
                    const newAccessToken = cryptoHelpers.getRandomToken();
                    CompetitionQueries.updateCompetitionAccessToken({ competitionId, newAccessToken })
                        .then(_updateResult => {
                            res.sendStatus(200);
                        })
                        .catch(error => {
                            handleError(error, 500, 'Failed to update competition token after removing user', res);
                        });
                })
                .catch(error => {
                    handleError(error, 500, 'Error removing user from competition', res);
                });
        })
        .catch(error => {
            handleError(error, 500, 'Error getting competition info', res);
        });
});

// Returns an overview of the given competition that contains a list of users and their current points for the competition
// The user must be a member of this competition in order to receive the data
//
// Expects a query param with the user's current timezone (to decide whether to show the competition as active or not)
router.get('/:competitionId/overview', function (req, res) {
    const timezoneParam = req.query['timezone']?.toString();
    const competitionId: string = req.params.competitionId;
    if (!timezoneParam || !allIANATimezones.includes(timezoneParam)) {
        handleError(null, 400, 'Invalid timezone query param: ' + timezoneParam, res);
        return;
    }

    // 1. Get the competition data and the users
    const userId = res.locals.oauth.token.user.id;
    Promise.all([
        UserQueries.getUsersInCompetition({ competitionId }),
        CompetitionQueries.getCompetition({ competitionId })
    ])
        .then(([usersCompetitionsResult, competitionsResult]) =>{
            if (!usersCompetitionsResult.length || !competitionsResult.length) {
                handleError(null, 404, 'Could not find competition info', res);
                return;
            }

            // 2. Check that the authenticated user is one of the members of this competition
            if (!usersCompetitionsResult.filter((row) => { return row.userId === userId }).length) {
                handleError(null, 401, 'User is not a member of the competition', res);
                return;
            }

            // 3. Calculate points for the activity data for all of the users in the competition in the competition date range
            const competitionInfo = competitionsResult[0];
            const isUserAdmin = userId === convertBufferToUserId(competitionInfo.admin_user_id);

            getCompetitionStandings(competitionInfo, usersCompetitionsResult, timezoneParam)
                .then(userPoints => {
                    // We don't announce results until 24hrs after the competition has ended
                    // This allows clients to report final data and users in different timezones to finish their days
                    const now = new Date();
                    const timeSinceCompetitionEnd =  now.getTime() - competitionInfo.end_date.getTime();
                    const isCompetitionProcessingResults = timeSinceCompetitionEnd > 0 && timeSinceCompetitionEnd < competitionResultProcessingTimeMs;

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
                .catch(error => {
                    handleError(error, 500, 'Error calculating results', res);
                });
        })
        .catch(error => {
            handleError(error, 500, 'Error getting competition info', res);
        });
});

// Returns a description of the competition containing the name, dates, and number of members of the competition
// The user does not need to be a member of the competition to get this info but they do need to have the competition access token
// Expects a competitionId and competitionAccessToken in the request body
router.post('/description', function (req, res) {
    const competitionId: string = req.body['competitionId'];
    const competitionToken: string = req.body['competitionAccessToken'];

    if (!competitionId || !competitionToken) {
        handleError(null, 400, 'Missing required param', res);
        return;
    }

    Promise.all([
        CompetitionQueries.getNumUsersInCompetition({ competitionId }),
        CompetitionQueries.getCompetitionDescriptionDetails({ competitionId, competitionAccessToken: competitionToken })
    ])
        .then(([usersCompetitionsResult, competitionsResult]) => {
            if (!usersCompetitionsResult.length || !competitionsResult.length) {
                handleError(null, 404, 'Could not find competition info', res);
                return;
            }

            const competitionInfo = competitionsResult[0];
            const numMembers = usersCompetitionsResult[0].count;

            // Find the display name of the competition admin so we can include it in the response
            UserQueries.getUserName({ userId: competitionInfo.admin_user_id })
                .then(adminNameResult => {
                    if (!adminNameResult.length) {
                        handleError(null, 500, 'Unexpected failure when looking up admin user info', res);
                        return;
                    }

                    const adminName = adminNameResult[0].first_name + ' ' + adminNameResult[0].last_name;

                    res.json({
                        'competitionName': competitionInfo.display_name,
                        'competitionStart': competitionInfo.start_date,
                        'competitionEnd': competitionInfo.end_date,
                        'numMembers': numMembers,
                        'adminName': adminName
                    });
                })
                .catch(error => {
                    handleError(error, 500, 'Error getting admin user details', res);
                });
        })
        .catch(error => {
            handleError(error, 500, 'Error getting description for competition', res);
        });
});

// Returns the competition access token for the given competition ID
// The authenticated user must be the admin of the competition to receive this data
router.get('/:competitionId/adminDetail', function (req, res) {
    const competitionId: string = req.params.competitionId;
    const userId: string = res.locals.oauth.token.user.id;
    CompetitionQueries.getCompetitionAdminDetails({ competitionId, adminUserId: convertUserIdToBuffer(userId) })
        .then(result => {
            if (!result.length) {
                handleError(null, 404, 'Competition not found or user is not admin', res);
                return;
            }

            const competitionInfo = result[0];
            res.json({
                'competitionAccessToken': competitionInfo.access_token,
                'competitionId': competitionInfo.competition_id
            });
        })
        .catch(error => {
            handleError(error, 500, 'Error getting competition admin info', res);
        });
});

// Deletes the given competition
// The authenticated user must the admin of the competition to perform this action
// The request body should have the competitionId to delete
router.post('/delete', function (req, res) {
    const competitionId: string = req.body['competitionId'];
    if (!competitionId) {
        handleError(null, 400, 'Missing required parameter competitionId', res);
        return;
    }

    // Confirm that the authenticated user is the admin
    const userId = res.locals.oauth.token.user.id;
    CompetitionQueries.getCompetitionAdminDetails({ competitionId, adminUserId: convertUserIdToBuffer(userId) })
        .then(result => {
            if (!result.length) {
                handleError(null, 404, 'Competition not found or user is not admin', res);
                return;
            }

            CompetitionQueries.deleteCompetition({ competitionId })
                .then(_result => {
                    res.sendStatus(200);
                })
                .catch(error => {
                    handleError(error, 500, 'Error deleting competition', res);
                });
        })
        .catch(error => {
            handleError(error, 500, 'Error getting competition admin info', res);
        });
});

export default router;

// Helper functions

// Checks that the user is under the max number of allowed active competitions
// Returns a Promise that will continue if the user user is allowed to join a new competition
// If the user cannot join a competition, then an error will be thrown
// Expects a hex-formated user ID as a parameter
function validateCompetitionCountLimit(userId: string): Promise<void> {
    // TODO: handle timezones for active competition count
    const currentDate = new Date();
    const userIdBuffer = convertUserIdToBuffer(userId);

    // Check if the user has already hit their max number of active competitions
    return new Promise<void>((resolve, reject) => {
        Promise.all([
            UserQueries.getUserMaxCompetitions({ userId: userIdBuffer }),
            CompetitionQueries.getNumberOfActiveCompetitionsForUser({ userId: userIdBuffer, currentDate })
        ]).then(([maxCompetitionResult, competitionCountResult]) => {
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
        }).catch(error => {
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