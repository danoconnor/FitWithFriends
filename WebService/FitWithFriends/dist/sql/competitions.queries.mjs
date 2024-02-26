/** Types generated for queries found in "sql/competitions.sql" */
import { PreparedQuery } from '@pgtyped/runtime';
const getUsersCompetitionsIR = { "usedParamSet": { "userId": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 62, "b": 69 }] }], "statement": "SELECT competition_id from users_competitions WHERE user_id = :userId!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT competition_id from users_competitions WHERE user_id = :userId!
 * ```
 */
export const getUsersCompetitions = new PreparedQuery(getUsersCompetitionsIR);
const createCompetitionIR = { "usedParamSet": { "startDate": true, "endDate": true, "displayName": true, "adminUserId": true, "accessToken": true, "ianaTimezone": true, "competitionId": true }, "params": [{ "name": "startDate", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 130, "b": 140 }] }, { "name": "endDate", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 143, "b": 151 }] }, { "name": "displayName", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 154, "b": 166 }] }, { "name": "adminUserId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 169, "b": 181 }] }, { "name": "accessToken", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 184, "b": 196 }] }, { "name": "ianaTimezone", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 199, "b": 212 }] }, { "name": "competitionId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 215, "b": 229 }] }], "statement": "INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id) VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!)" };
/**
 * Query generated from SQL:
 * ```
 * INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id) VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!)
 * ```
 */
export const createCompetition = new PreparedQuery(createCompetitionIR);
const addUserToCompetitionIR = { "usedParamSet": { "userId": true, "competitionId": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 66, "b": 73 }] }, { "name": "competitionId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 76, "b": 90 }] }], "statement": "INSERT INTO users_competitions (user_id, competition_id) \nVALUES (:userId!, :competitionId!)\nON CONFLICT (user_id, competition_id) DO NOTHING" };
/**
 * Query generated from SQL:
 * ```
 * INSERT INTO users_competitions (user_id, competition_id)
 * VALUES (:userId!, :competitionId!)
 * ON CONFLICT (user_id, competition_id) DO NOTHING
 * ```
 */
export const addUserToCompetition = new PreparedQuery(addUserToCompetitionIR);
const getCompetitionIR = { "usedParamSet": { "competitionId": true }, "params": [{ "name": "competitionId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 216, "b": 230 }] }], "statement": "                                                                                      \nSELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id FROM competitions WHERE competition_id = :competitionId!" };
/**
 * Query generated from SQL:
 * ```
 *
 * SELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id FROM competitions WHERE competition_id = :competitionId!
 * ```
 */
export const getCompetition = new PreparedQuery(getCompetitionIR);
const getCompetitionAdminDetailsIR = { "usedParamSet": { "competitionId": true, "adminUserId": true }, "params": [{ "name": "competitionId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 143, "b": 157 }] }, { "name": "adminUserId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 179, "b": 191 }] }], "statement": "SELECT start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id FROM competitions WHERE competition_id = :competitionId! AND admin_user_id = :adminUserId!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id FROM competitions WHERE competition_id = :competitionId! AND admin_user_id = :adminUserId!
 * ```
 */
export const getCompetitionAdminDetails = new PreparedQuery(getCompetitionAdminDetailsIR);
const getNumUsersInCompetitionIR = { "usedParamSet": { "competitionId": true }, "params": [{ "name": "competitionId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 78, "b": 92 }] }], "statement": "SELECT count(user_id)::INTEGER FROM users_competitions WHERE competition_id = :competitionId!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT count(user_id)::INTEGER FROM users_competitions WHERE competition_id = :competitionId!
 * ```
 */
export const getNumUsersInCompetition = new PreparedQuery(getNumUsersInCompetitionIR);
const getCompetitionDescriptionDetailsIR = { "usedParamSet": { "competitionId": true, "competitionAccessToken": true }, "params": [{ "name": "competitionId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 217, "b": 231 }] }, { "name": "competitionAccessToken", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 252, "b": 275 }] }], "statement": "                                                                                                                      \nSELECT start_date, end_date, display_name, admin_user_id FROM competitions WHERE competition_id = :competitionId! AND access_token = :competitionAccessToken!" };
/**
 * Query generated from SQL:
 * ```
 *
 * SELECT start_date, end_date, display_name, admin_user_id FROM competitions WHERE competition_id = :competitionId! AND access_token = :competitionAccessToken!
 * ```
 */
export const getCompetitionDescriptionDetails = new PreparedQuery(getCompetitionDescriptionDetailsIR);
const deleteUserFromCompetitionIR = { "usedParamSet": { "userId": true, "competitionId": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 47, "b": 54 }] }, { "name": "competitionId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 77, "b": 91 }] }], "statement": "DELETE FROM users_competitions WHERE user_id = :userId! AND competition_id = :competitionId!" };
/**
 * Query generated from SQL:
 * ```
 * DELETE FROM users_competitions WHERE user_id = :userId! AND competition_id = :competitionId!
 * ```
 */
export const deleteUserFromCompetition = new PreparedQuery(deleteUserFromCompetitionIR);
const updateCompetitionAccessTokenIR = { "usedParamSet": { "newAccessToken": true, "competitionId": true }, "params": [{ "name": "newAccessToken", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 39, "b": 54 }] }, { "name": "competitionId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 79, "b": 93 }] }], "statement": "UPDATE competitions SET access_token = :newAccessToken! WHERE competition_id = :competitionId!" };
/**
 * Query generated from SQL:
 * ```
 * UPDATE competitions SET access_token = :newAccessToken! WHERE competition_id = :competitionId!
 * ```
 */
export const updateCompetitionAccessToken = new PreparedQuery(updateCompetitionAccessTokenIR);
const getNumberOfActiveCompetitionsForUserIR = { "usedParamSet": { "userId": true, "currentDate": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 126, "b": 133 }] }, { "name": "currentDate", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 341, "b": 353 }] }], "statement": "SELECT COUNT(competitionData.competition_id)::INTEGER FROM\n    (SELECT competition_id FROM users_competitions WHERE user_id = :userId!) as usersCompetitions\n    INNER JOIN\n        (SELECT competition_id, end_date FROM competitions) as competitionData\n    ON usersCompetitions.competition_id = competitionData.competition_id\nWHERE end_date > :currentDate!" };
/**
 * Query generated from SQL:
 * ```
 * SELECT COUNT(competitionData.competition_id)::INTEGER FROM
 *     (SELECT competition_id FROM users_competitions WHERE user_id = :userId!) as usersCompetitions
 *     INNER JOIN
 *         (SELECT competition_id, end_date FROM competitions) as competitionData
 *     ON usersCompetitions.competition_id = competitionData.competition_id
 * WHERE end_date > :currentDate!
 * ```
 */
export const getNumberOfActiveCompetitionsForUser = new PreparedQuery(getNumberOfActiveCompetitionsForUserIR);
const deleteCompetitionIR = { "usedParamSet": { "competitionId": true }, "params": [{ "name": "competitionId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 48, "b": 62 }] }], "statement": "DELETE FROM competitions WHERE competition_id = :competitionId!" };
/**
 * Query generated from SQL:
 * ```
 * DELETE FROM competitions WHERE competition_id = :competitionId!
 * ```
 */
export const deleteCompetition = new PreparedQuery(deleteCompetitionIR);
