/** Types generated for queries found in "sql/pushNotifications.sql" */
import { PreparedQuery } from '@pgtyped/runtime';
const registerPushTokenIR = { "usedParamSet": { "userId": true, "pushToken": true, "platform": true }, "params": [{ "name": "userId", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 64, "b": 71 }] }, { "name": "pushToken", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 74, "b": 84 }] }, { "name": "platform", "required": true, "transform": { "type": "scalar" }, "locs": [{ "a": 87, "b": 96 }] }], "statement": "INSERT INTO push_tokens(user_id, push_token, platform) \nVALUES (:userId!, :pushToken!, :platform!)\nON CONFLICT (user_id, push_token, platform) DO NOTHING" };
/**
 * Query generated from SQL:
 * ```
 * INSERT INTO push_tokens(user_id, push_token, platform)
 * VALUES (:userId!, :pushToken!, :platform!)
 * ON CONFLICT (user_id, push_token, platform) DO NOTHING
 * ```
 */
export const registerPushToken = new PreparedQuery(registerPushTokenIR);
