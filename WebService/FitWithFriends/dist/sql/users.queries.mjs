/** Types generated for queries found in "sql/users.sql" */
import { PreparedQuery } from '@pgtyped/runtime';
const createUserIR = { "usedParamSet": { "userId": true, "firstName": true, "lastName": true, "maxActiveCompetitions": true, "isPro": true, "createdDate": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 105, "b": 112 }] }, { "name": "firstName", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 115, "b": 125 }] }, { "name": "lastName", "required": false, "transform": { "type": "scalar" }, "locs": [{ "a": 128, "b": 136 }] }, { "name": "maxActiveCompetitions", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 139, "b": 161 }] }, { "name": "isPro", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 164, "b": 170 }] }, { "name": "createdDate", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 173, "b": 185 }] }], "statement": "INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!)" };
/**
 * Query generated from SQL:
 * ```
 * INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!)
 * ```
 */
export const createUser = new PreparedQuery(createUserIR);
const getUserNameIR = { "usedParamSet": { "userId": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 56, "b": 63 }] }], "statement": "SELECT first_name, last_name FROM users WHERE user_id = :userId!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT first_name, last_name FROM users WHERE user_id = :userId!
 * ```
 */
export const getUserName = new PreparedQuery(getUserNameIR);
const getUserMaxCompetitionsIR = { "usedParamSet": { "userId": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 58, "b": 65 }] }], "statement": "SELECT max_active_competitions FROM users WHERE user_id = :userId!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT max_active_competitions FROM users WHERE user_id = :userId!
 * ```
 */
export const getUserMaxCompetitions = new PreparedQuery(getUserMaxCompetitionsIR);
const getUsersInCompetitionIR = { "usedParamSet": { "competitionId": true }, "params": [{ "name": "competitionId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 172, "b": 186 }] }], "statement": "SELECT encode(userData.user_id::bytea, 'hex') AS \"userId!\", userData.first_name, userData.last_name FROM\n    (SELECT user_id FROM users_competitions WHERE competition_id = :competitionId!) AS usersCompetitions\n    INNER JOIN (SELECT user_id, first_name, last_name FROM users) as userData\n    ON usersCompetitions.user_id = userData.user_id" };
/**
 * Query generated from SQL:
 * ```
 * SELECT encode(userData.user_id::bytea, 'hex') AS "userId!", userData.first_name, userData.last_name FROM
 *     (SELECT user_id FROM users_competitions WHERE competition_id = :competitionId!) AS usersCompetitions
 *     INNER JOIN (SELECT user_id, first_name, last_name FROM users) as userData
 *     ON usersCompetitions.user_id = userData.user_id
 * ```
 */
export const getUsersInCompetition = new PreparedQuery(getUsersInCompetitionIR);
