/** Types generated for queries found in "test/sql/testQueries.sql" */
import { DatabaseConnectionPool } from '../../utilities/database';

export type DateOrString = Date | string;

/** 'ClearAllData' parameters type */
export type IClearAllDataParams = void;

/** 'ClearAllData' return type */
export type IClearAllDataResult = void;

/** 'ClearAllData' query type */
export interface IClearAllDataQuery {
  params: IClearAllDataParams;
  result: IClearAllDataResult;
}

const clearAllDataIR: any = {"usedParamSet":{},"params":[],"statement":"                                                                                                                                               \nDELETE FROM users"};

/**
 * Query generated from SQL:
 * ```
 *                                                                                                                                                
 * DELETE FROM users
 * ```
 */
export function clearAllData(params: IClearAllDataParams): Promise<Array<IClearAllDataResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const clearAllData = new pgtyped.PreparedQuery<IClearAllDataParams,IClearAllDataResult>(clearAllDataIR);
    return clearAllData.run(params, DatabaseConnectionPool);
  });
}


/** 'CreateUser' parameters type */
export interface ICreateUserParams {
  createdDate: DateOrString;
  firstName: string;
  isPro: boolean;
  lastName?: string | null | void;
  maxActiveCompetitions: number;
  userId: Buffer;
}

/** 'CreateUser' return type */
export type ICreateUserResult = void;

/** 'CreateUser' query type */
export interface ICreateUserQuery {
  params: ICreateUserParams;
  result: ICreateUserResult;
}

const createUserIR: any = {"usedParamSet":{"userId":true,"firstName":true,"lastName":true,"maxActiveCompetitions":true,"isPro":true,"createdDate":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":105,"b":112}]},{"name":"firstName","required":true,"transform":{"type":"scalar"},"locs":[{"a":115,"b":125}]},{"name":"lastName","required":false,"transform":{"type":"scalar"},"locs":[{"a":128,"b":136}]},{"name":"maxActiveCompetitions","required":true,"transform":{"type":"scalar"},"locs":[{"a":139,"b":161}]},{"name":"isPro","required":true,"transform":{"type":"scalar"},"locs":[{"a":164,"b":170}]},{"name":"createdDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":173,"b":185}]}],"statement":"INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!)
 * ```
 */
export function createUser(params: ICreateUserParams): Promise<Array<ICreateUserResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const createUser = new pgtyped.PreparedQuery<ICreateUserParams,ICreateUserResult>(createUserIR);
    return createUser.run(params, DatabaseConnectionPool);
  });
}


/** 'CreateRefreshToken' parameters type */
export interface ICreateRefreshTokenParams {
  clientId: string;
  refreshToken: string;
  refreshTokenExpiresOn: DateOrString;
  userId: Buffer;
}

/** 'CreateRefreshToken' return type */
export type ICreateRefreshTokenResult = void;

/** 'CreateRefreshToken' query type */
export interface ICreateRefreshTokenQuery {
  params: ICreateRefreshTokenParams;
  result: ICreateRefreshTokenResult;
}

const createRefreshTokenIR: any = {"usedParamSet":{"refreshToken":true,"refreshTokenExpiresOn":true,"userId":true,"clientId":true},"params":[{"name":"refreshToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":94,"b":107}]},{"name":"refreshTokenExpiresOn","required":true,"transform":{"type":"scalar"},"locs":[{"a":110,"b":132}]},{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":135,"b":142}]},{"name":"clientId","required":true,"transform":{"type":"scalar"},"locs":[{"a":145,"b":154}]}],"statement":"INSERT INTO oauth_tokens(refresh_token, refresh_token_expires_on, user_id, client_id) VALUES (:refreshToken!, :refreshTokenExpiresOn!, :userId!, :clientId!)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO oauth_tokens(refresh_token, refresh_token_expires_on, user_id, client_id) VALUES (:refreshToken!, :refreshTokenExpiresOn!, :userId!, :clientId!)
 * ```
 */
export function createRefreshToken(params: ICreateRefreshTokenParams): Promise<Array<ICreateRefreshTokenResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const createRefreshToken = new pgtyped.PreparedQuery<ICreateRefreshTokenParams,ICreateRefreshTokenResult>(createRefreshTokenIR);
    return createRefreshToken.run(params, DatabaseConnectionPool);
  });
}


/** 'GetUser' parameters type */
export interface IGetUserParams {
  userId: Buffer;
}

/** 'GetUser' return type */
export interface IGetUserResult {
  created_date: Date;
  first_name: string;
  is_pro: boolean;
  last_name: string | null;
  max_active_competitions: number;
  user_id: Buffer;
}

/** 'GetUser' query type */
export interface IGetUserQuery {
  params: IGetUserParams;
  result: IGetUserResult;
}

const getUserIR: any = {"usedParamSet":{"userId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":36,"b":43}]}],"statement":"SELECT * FROM users WHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT * FROM users WHERE user_id = :userId!
 * ```
 */
export function getUser(params: IGetUserParams): Promise<Array<IGetUserResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getUser = new pgtyped.PreparedQuery<IGetUserParams,IGetUserResult>(getUserIR);
    return getUser.run(params, DatabaseConnectionPool);
  });
}


/** 'GetActivitySummariesForUser' parameters type */
export interface IGetActivitySummariesForUserParams {
  userId: Buffer;
}

/** 'GetActivitySummariesForUser' return type */
export interface IGetActivitySummariesForUserResult {
  calories_burned: number;
  calories_goal: number;
  date: Date;
  exercise_time: number;
  exercise_time_goal: number;
  stand_time: number;
  stand_time_goal: number;
  user_id: Buffer;
}

/** 'GetActivitySummariesForUser' query type */
export interface IGetActivitySummariesForUserQuery {
  params: IGetActivitySummariesForUserParams;
  result: IGetActivitySummariesForUserResult;
}

const getActivitySummariesForUserIR: any = {"usedParamSet":{"userId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":49,"b":56}]}],"statement":"SELECT * FROM activity_summaries WHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT * FROM activity_summaries WHERE user_id = :userId!
 * ```
 */
export function getActivitySummariesForUser(params: IGetActivitySummariesForUserParams): Promise<Array<IGetActivitySummariesForUserResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getActivitySummariesForUser = new pgtyped.PreparedQuery<IGetActivitySummariesForUserParams,IGetActivitySummariesForUserResult>(getActivitySummariesForUserIR);
    return getActivitySummariesForUser.run(params, DatabaseConnectionPool);
  });
}


