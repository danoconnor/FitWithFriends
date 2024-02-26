/** Types generated for queries found in "sql/pushNotifications.sql" */
import { PreparedQuery } from '@pgtyped/runtime';

/** 'RegisterPushToken' parameters type */
export interface IRegisterPushTokenParams {
  platform: number;
  pushToken: string;
  userId: Buffer;
}

/** 'RegisterPushToken' return type */
export type IRegisterPushTokenResult = void;

/** 'RegisterPushToken' query type */
export interface IRegisterPushTokenQuery {
  params: IRegisterPushTokenParams;
  result: IRegisterPushTokenResult;
}

const registerPushTokenIR: any = {"usedParamSet":{"userId":true,"pushToken":true,"platform":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":64,"b":71}]},{"name":"pushToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":74,"b":84}]},{"name":"platform","required":true,"transform":{"type":"scalar"},"locs":[{"a":87,"b":96}]}],"statement":"INSERT INTO push_tokens(user_id, push_token, platform) \nVALUES (:userId!, :pushToken!, :platform!)\nON CONFLICT (user_id, push_token, platform) DO NOTHING"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO push_tokens(user_id, push_token, platform) 
 * VALUES (:userId!, :pushToken!, :platform!)
 * ON CONFLICT (user_id, push_token, platform) DO NOTHING
 * ```
 */
export const registerPushToken = new PreparedQuery<IRegisterPushTokenParams,IRegisterPushTokenResult>(registerPushTokenIR);


