"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getUsersInCompetition = exports.getUserMaxCompetitions = exports.getUserName = exports.createUser = void 0;
/** Types generated for queries found in "sql/users.sql" */
var runtime_1 = require("@pgtyped/runtime");
var createUserIR = { "usedParamSet": { "userId": true, "firstName": true, "lastName": true, "maxActiveCompetitions": true, "isPro": true, "createdDate": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 105, "b": 112 }] }, { "name": "firstName", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 115, "b": 125 }] }, { "name": "lastName", "required": false, "transform": { "type": "scalar" }, "locs": [{ "a": 128, "b": 136 }] }, { "name": "maxActiveCompetitions", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 139, "b": 161 }] }, { "name": "isPro", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 164, "b": 170 }] }, { "name": "createdDate", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 173, "b": 185 }] }], "statement": "INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!)" };
/**
 * Query generated from SQL:
 * ```
 * INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!)
 * ```
 */
exports.createUser = new runtime_1.PreparedQuery(createUserIR);
var getUserNameIR = { "usedParamSet": { "userId": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 56, "b": 63 }] }], "statement": "SELECT first_name, last_name FROM users WHERE user_id = :userId!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT first_name, last_name FROM users WHERE user_id = :userId!
 * ```
 */
exports.getUserName = new runtime_1.PreparedQuery(getUserNameIR);
var getUserMaxCompetitionsIR = { "usedParamSet": { "userId": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 58, "b": 65 }] }], "statement": "SELECT max_active_competitions FROM users WHERE user_id = :userId!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT max_active_competitions FROM users WHERE user_id = :userId!
 * ```
 */
exports.getUserMaxCompetitions = new runtime_1.PreparedQuery(getUserMaxCompetitionsIR);
var getUsersInCompetitionIR = { "usedParamSet": { "competitionId": true }, "params": [{ "name": "competitionId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 172, "b": 186 }] }], "statement": "SELECT encode(userData.user_id::bytea, 'hex') AS \"userId!\", userData.first_name, userData.last_name FROM\n    (SELECT user_id FROM users_competitions WHERE competition_id = :competitionId!) AS usersCompetitions\n    INNER JOIN (SELECT user_id, first_name, last_name FROM users) as userData\n    ON usersCompetitions.user_id = userData.user_id" };
/**
 * Query generated from SQL:
 * ```
 * SELECT encode(userData.user_id::bytea, 'hex') AS "userId!", userData.first_name, userData.last_name FROM
 *     (SELECT user_id FROM users_competitions WHERE competition_id = :competitionId!) AS usersCompetitions
 *     INNER JOIN (SELECT user_id, first_name, last_name FROM users) as userData
 *     ON usersCompetitions.user_id = userData.user_id
 * ```
 */
exports.getUsersInCompetition = new runtime_1.PreparedQuery(getUsersInCompetitionIR);
