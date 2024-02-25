"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getActivitySummariesForUsers = void 0;
/** Types generated for queries found in "sql/activitySummaries.sql" */
var runtime_1 = require("@pgtyped/runtime");
var getActivitySummariesForUsersIR = { "usedParamSet": { "userIds": true, "endDate": true, "startDate": true }, "params": [{ "name": "userIds", "required": true, "transform": { "type": "array_spread" }, "locs": [{ "a": 279, "b": 287 }] }, { "name": "endDate", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 301, "b": 309 }] }, { "name": "startDate", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 323, "b": 333 }] }], "statement": "                                                                                    \nSELECT encode(user_id::bytea, 'hex') AS \"userId!\", date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal \nFROM activity_summaries\nWHERE user_id in :userIds! AND date <= :endDate! AND date >= :startDate!" };
/**
 * Query generated from SQL:
 * ```
 *
 * SELECT encode(user_id::bytea, 'hex') AS "userId!", date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal
 * FROM activity_summaries
 * WHERE user_id in :userIds! AND date <= :endDate! AND date >= :startDate!
 * ```
 */
exports.getActivitySummariesForUsers = new runtime_1.PreparedQuery(getActivitySummariesForUsersIR);
