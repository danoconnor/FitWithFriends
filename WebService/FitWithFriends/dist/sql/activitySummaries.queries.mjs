/** Types generated for queries found in "sql/activitySummaries.sql" */
import { PreparedQuery } from '@pgtyped/runtime';
const getActivitySummariesForUsersIR = { "usedParamSet": { "userIds": true, "endDate": true, "startDate": true }, "params": [{ "name": "userIds", "required": true, "transform": { "type": "array_spread" }, "locs": [{ "a": 279, "b": 287 }] }, { "name": "endDate", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 301, "b": 309 }] }, { "name": "startDate", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 323, "b": 333 }] }], "statement": "                                                                                    \nSELECT encode(user_id::bytea, 'hex') AS \"userId!\", date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal \nFROM activity_summaries\nWHERE user_id in :userIds! AND date <= :endDate! AND date >= :startDate!" };
/**
 * Query generated from SQL:
 * ```
 *
 * SELECT encode(user_id::bytea, 'hex') AS "userId!", date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal
 * FROM activity_summaries
 * WHERE user_id in :userIds! AND date <= :endDate! AND date >= :startDate!
 * ```
 */
export const getActivitySummariesForUsers = new PreparedQuery(getActivitySummariesForUsersIR);
const insertActivitySummaryIR = { "usedParamSet": { "userId": true, "date": true, "caloriesBurned": true, "caloriesGoal": true, "exerciseTime": true, "exerciseTimeGoal": true, "standTime": true, "standTimeGoal": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 150, "b": 157 }] }, { "name": "date", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 160, "b": 165 }] }, { "name": "caloriesBurned", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 168, "b": 183 }] }, { "name": "caloriesGoal", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 186, "b": 199 }] }, { "name": "exerciseTime", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 202, "b": 215 }] }, { "name": "exerciseTimeGoal", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 218, "b": 235 }] }, { "name": "standTime", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 238, "b": 248 }] }, { "name": "standTimeGoal", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 251, "b": 265 }] }], "statement": "INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal)\nVALUES (:userId!, :date!, :caloriesBurned!, :caloriesGoal!, :exerciseTime!, :exerciseTimeGoal!, :standTime!, :standTimeGoal!)\nON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal" };
/**
 * Query generated from SQL:
 * ```
 * INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal)
 * VALUES (:userId!, :date!, :caloriesBurned!, :caloriesGoal!, :exerciseTime!, :exerciseTimeGoal!, :standTime!, :standTimeGoal!)
 * ON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal
 * ```
 */
export const insertActivitySummary = new PreparedQuery(insertActivitySummaryIR);
