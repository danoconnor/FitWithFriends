/** Types generated for queries found in "sql/pushNotifications.sql" */
import { DatabaseConnectionPool } from '../utilities/database';

/** 'RegisterPushToken' parameters type */
export interface IRegisterPushTokenParams {
  appInstallId: string;
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

const registerPushTokenIR: any = {"usedParamSet":{"userId":true,"pushToken":true,"platform":true,"appInstallId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":80,"b":87}]},{"name":"pushToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":90,"b":100}]},{"name":"platform","required":true,"transform":{"type":"scalar"},"locs":[{"a":103,"b":112}]},{"name":"appInstallId","required":true,"transform":{"type":"scalar"},"locs":[{"a":115,"b":128}]}],"statement":"INSERT INTO push_tokens(user_id, push_token, platform, app_install_id) \nVALUES (:userId!, :pushToken!, :platform!, :appInstallId!)\nON CONFLICT (user_id, platform, app_install_id) DO UPDATE SET push_token = EXCLUDED.push_token"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO push_tokens(user_id, push_token, platform, app_install_id) 
 * VALUES (:userId!, :pushToken!, :platform!, :appInstallId!)
 * ON CONFLICT (user_id, platform, app_install_id) DO UPDATE SET push_token = EXCLUDED.push_token
 * ```
 */
export function registerPushToken(params: IRegisterPushTokenParams): Promise<Array<IRegisterPushTokenResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const registerPushToken = new pgtyped.PreparedQuery<IRegisterPushTokenParams,IRegisterPushTokenResult>(registerPushTokenIR);
    return registerPushToken.run(params, DatabaseConnectionPool);
  });
}


