/** Types generated for queries found in "sql/oauth.sql" */
import { DatabaseConnectionPool } from '../utilities/database';

export type DateOrString = Date | string;

/** 'GetClient' parameters type */
export interface IGetClientParams {
  clientId: string;
  clientSecret: string;
}

/** 'GetClient' return type */
export interface IGetClientResult {
  client_id: string;
  client_secret: string;
  redirect_uri: string;
}

/** 'GetClient' query type */
export interface IGetClientQuery {
  params: IGetClientParams;
  result: IGetClientResult;
}

const getClientIR: any = {"usedParamSet":{"clientId":true,"clientSecret":true},"params":[{"name":"clientId","required":true,"transform":{"type":"scalar"},"locs":[{"a":83,"b":92}]},{"name":"clientSecret","required":true,"transform":{"type":"scalar"},"locs":[{"a":114,"b":127}]}],"statement":"SELECT client_id, client_secret, redirect_uri FROM oauth_clients WHERE client_id = :clientId! AND client_secret = :clientSecret!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT client_id, client_secret, redirect_uri FROM oauth_clients WHERE client_id = :clientId! AND client_secret = :clientSecret!
 * ```
 */
export function getClient(params: IGetClientParams): Promise<IGetClientResult[]> {
  return import('@pgtyped/runtime').then((pgtyped) => {
    const getClient = new pgtyped.PreparedQuery<IGetClientParams,IGetClientResult>(getClientIR);
    return getClient.run(params, DatabaseConnectionPool);
  });
}


/** 'GetRefreshToken' parameters type */
export interface IGetRefreshTokenParams {
  refreshToken: string;
}

/** 'GetRefreshToken' return type */
export interface IGetRefreshTokenResult {
  client_id: string;
  refresh_token: string;
  refresh_token_expires_on: Date;
  user_id: Buffer;
}

/** 'GetRefreshToken' query type */
export interface IGetRefreshTokenQuery {
  params: IGetRefreshTokenParams;
  result: IGetRefreshTokenResult;
}

const getRefreshTokenIR: any = {"usedParamSet":{"refreshToken":true},"params":[{"name":"refreshToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":107,"b":120}]}],"statement":"SELECT client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE refresh_token = :refreshToken!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE refresh_token = :refreshToken!
 * ```
 */
export function getRefreshToken(params: IGetRefreshTokenParams): Promise<IGetRefreshTokenResult[]> {
  return import('@pgtyped/runtime').then((pgtyped) => {
    const getRefreshToken = new pgtyped.PreparedQuery<IGetRefreshTokenParams,IGetRefreshTokenResult>(getRefreshTokenIR);
    return getRefreshToken.run(params, DatabaseConnectionPool);
  });
}


/** 'SaveRefreshToken' parameters type */
export interface ISaveRefreshTokenParams {
  clientId: string;
  refreshToken: string;
  refreshTokenExpiresOn: DateOrString;
  userId: Buffer;
}

/** 'SaveRefreshToken' return type */
export type ISaveRefreshTokenResult = void;

/** 'SaveRefreshToken' query type */
export interface ISaveRefreshTokenQuery {
  params: ISaveRefreshTokenParams;
  result: ISaveRefreshTokenResult;
}

const saveRefreshTokenIR: any = {"usedParamSet":{"clientId":true,"refreshToken":true,"refreshTokenExpiresOn":true,"userId":true},"params":[{"name":"clientId","required":true,"transform":{"type":"scalar"},"locs":[{"a":94,"b":103}]},{"name":"refreshToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":106,"b":119}]},{"name":"refreshTokenExpiresOn","required":true,"transform":{"type":"scalar"},"locs":[{"a":122,"b":144}]},{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":147,"b":154}]}],"statement":"INSERT INTO oauth_tokens(client_id, refresh_token, refresh_token_expires_on, user_id) VALUES (:clientId!, :refreshToken!, :refreshTokenExpiresOn!, :userId!)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO oauth_tokens(client_id, refresh_token, refresh_token_expires_on, user_id) VALUES (:clientId!, :refreshToken!, :refreshTokenExpiresOn!, :userId!)
 * ```
 */
export function saveRefreshToken(params: ISaveRefreshTokenParams): Promise<ISaveRefreshTokenResult | ISaveRefreshTokenResult[]> {
  return import('@pgtyped/runtime').then((pgtyped) => {
    const saveRefreshToken = new pgtyped.PreparedQuery<ISaveRefreshTokenParams,ISaveRefreshTokenResult>(saveRefreshTokenIR);
    return saveRefreshToken.run(params, DatabaseConnectionPool);
  });
}


/** 'DeleteRefreshToken' parameters type */
export interface IDeleteRefreshTokenParams {
  refreshToken: string;
}

/** 'DeleteRefreshToken' return type */
export type IDeleteRefreshTokenResult = void;

/** 'DeleteRefreshToken' query type */
export interface IDeleteRefreshTokenQuery {
  params: IDeleteRefreshTokenParams;
  result: IDeleteRefreshTokenResult;
}

const deleteRefreshTokenIR: any = {"usedParamSet":{"refreshToken":true},"params":[{"name":"refreshToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":47,"b":60}]}],"statement":"DELETE FROM oauth_tokens WHERE refresh_token = :refreshToken!"};

/**
 * Query generated from SQL:
 * ```
 * DELETE FROM oauth_tokens WHERE refresh_token = :refreshToken!
 * ```
 */
export function deleteRefreshToken(params: IDeleteRefreshTokenParams): Promise<IDeleteRefreshTokenResult | IDeleteRefreshTokenResult[]> {
  return import('@pgtyped/runtime').then((pgtyped) => {
    const deleteRefreshToken = new pgtyped.PreparedQuery<IDeleteRefreshTokenParams,IDeleteRefreshTokenResult>(deleteRefreshTokenIR);
    return deleteRefreshToken.run(params, DatabaseConnectionPool);
  });
}


