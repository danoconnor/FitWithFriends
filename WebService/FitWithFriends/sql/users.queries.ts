/** Types generated for queries found in "sql/users.sql" */
import { DatabaseConnectionPool } from '../utilities/database';

export type DateOrString = Date | string;

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


/** 'GetUserName' parameters type */
export interface IGetUserNameParams {
  userId: Buffer;
}

/** 'GetUserName' return type */
export interface IGetUserNameResult {
  first_name: string;
  last_name: string | null;
}

/** 'GetUserName' query type */
export interface IGetUserNameQuery {
  params: IGetUserNameParams;
  result: IGetUserNameResult;
}

const getUserNameIR: any = {"usedParamSet":{"userId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":56,"b":63}]}],"statement":"SELECT first_name, last_name FROM users WHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT first_name, last_name FROM users WHERE user_id = :userId!
 * ```
 */
export function getUserName(params: IGetUserNameParams): Promise<Array<IGetUserNameResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getUserName = new pgtyped.PreparedQuery<IGetUserNameParams,IGetUserNameResult>(getUserNameIR);
    return getUserName.run(params, DatabaseConnectionPool);
  });
}


/** 'GetUserMaxCompetitions' parameters type */
export interface IGetUserMaxCompetitionsParams {
  userId: Buffer;
}

/** 'GetUserMaxCompetitions' return type */
export interface IGetUserMaxCompetitionsResult {
  max_active_competitions: number;
}

/** 'GetUserMaxCompetitions' query type */
export interface IGetUserMaxCompetitionsQuery {
  params: IGetUserMaxCompetitionsParams;
  result: IGetUserMaxCompetitionsResult;
}

const getUserMaxCompetitionsIR: any = {"usedParamSet":{"userId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":58,"b":65}]}],"statement":"SELECT max_active_competitions FROM users WHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT max_active_competitions FROM users WHERE user_id = :userId!
 * ```
 */
export function getUserMaxCompetitions(params: IGetUserMaxCompetitionsParams): Promise<Array<IGetUserMaxCompetitionsResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getUserMaxCompetitions = new pgtyped.PreparedQuery<IGetUserMaxCompetitionsParams,IGetUserMaxCompetitionsResult>(getUserMaxCompetitionsIR);
    return getUserMaxCompetitions.run(params, DatabaseConnectionPool);
  });
}


/** 'GetUsersInCompetition' parameters type */
export interface IGetUsersInCompetitionParams {
  competitionId: string;
}

/** 'GetUsersInCompetition' return type */
export interface IGetUsersInCompetitionResult {
  finalPoints: number;
  first_name: string;
  last_name: string | null;
  userId: string;
}

/** 'GetUsersInCompetition' query type */
export interface IGetUsersInCompetitionQuery {
  params: IGetUsersInCompetitionParams;
  result: IGetUsersInCompetitionResult;
}

const getUsersInCompetitionIR: any = {"usedParamSet":{"competitionId":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":236,"b":250}]}],"statement":"SELECT encode(userData.user_id::bytea, 'hex') AS \"userId!\", userData.first_name, userData.last_name, usersCompetitions.final_points AS \"finalPoints!\" FROM\n    (SELECT user_id, final_points FROM users_competitions WHERE competition_id = :competitionId!) AS usersCompetitions\n    INNER JOIN (SELECT user_id, first_name, last_name FROM users) as userData\n    ON usersCompetitions.user_id = userData.user_id"};

/**
 * Query generated from SQL:
 * ```
 * SELECT encode(userData.user_id::bytea, 'hex') AS "userId!", userData.first_name, userData.last_name, usersCompetitions.final_points AS "finalPoints!" FROM
 *     (SELECT user_id, final_points FROM users_competitions WHERE competition_id = :competitionId!) AS usersCompetitions
 *     INNER JOIN (SELECT user_id, first_name, last_name FROM users) as userData
 *     ON usersCompetitions.user_id = userData.user_id
 * ```
 */
export function getUsersInCompetition(params: IGetUsersInCompetitionParams): Promise<Array<IGetUsersInCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getUsersInCompetition = new pgtyped.PreparedQuery<IGetUsersInCompetitionParams,IGetUsersInCompetitionResult>(getUsersInCompetitionIR);
    return getUsersInCompetition.run(params, DatabaseConnectionPool);
  });
}


/** 'GetUserProStatus' parameters type */
export interface IGetUserProStatusParams {
  userId: Buffer;
}

/** 'GetUserProStatus' return type */
export interface IGetUserProStatusResult {
  is_pro: boolean;
}

/** 'GetUserProStatus' query type */
export interface IGetUserProStatusQuery {
  params: IGetUserProStatusParams;
  result: IGetUserProStatusResult;
}

const getUserProStatusIR: any = {"usedParamSet":{"userId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":41,"b":48}]}],"statement":"SELECT is_pro FROM users WHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT is_pro FROM users WHERE user_id = :userId!
 * ```
 */
export function getUserProStatus(params: IGetUserProStatusParams): Promise<Array<IGetUserProStatusResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getUserProStatus = new pgtyped.PreparedQuery<IGetUserProStatusParams,IGetUserProStatusResult>(getUserProStatusIR);
    return getUserProStatus.run(params, DatabaseConnectionPool);
  });
}


/** 'UpdateUserProStatus' parameters type */
export interface IUpdateUserProStatusParams {
  isPro: boolean;
  maxActiveCompetitions: number;
  userId: Buffer;
}

/** 'UpdateUserProStatus' return type */
export type IUpdateUserProStatusResult = void;

/** 'UpdateUserProStatus' query type */
export interface IUpdateUserProStatusQuery {
  params: IUpdateUserProStatusParams;
  result: IUpdateUserProStatusResult;
}

const updateUserProStatusIR: any = {"usedParamSet":{"isPro":true,"maxActiveCompetitions":true,"userId":true},"params":[{"name":"isPro","required":true,"transform":{"type":"scalar"},"locs":[{"a":26,"b":32}]},{"name":"maxActiveCompetitions","required":true,"transform":{"type":"scalar"},"locs":[{"a":61,"b":83}]},{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":101,"b":108}]}],"statement":"UPDATE users SET is_pro = :isPro!, max_active_competitions = :maxActiveCompetitions!\nWHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 * UPDATE users SET is_pro = :isPro!, max_active_competitions = :maxActiveCompetitions!
 * WHERE user_id = :userId!
 * ```
 */
export function updateUserProStatus(params: IUpdateUserProStatusParams): Promise<Array<IUpdateUserProStatusResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const updateUserProStatus = new pgtyped.PreparedQuery<IUpdateUserProStatusParams,IUpdateUserProStatusResult>(updateUserProStatusIR);
    return updateUserProStatus.run(params, DatabaseConnectionPool);
  });
}


/** 'UpdateUserSubscriptionInfo' parameters type */
export interface IUpdateUserSubscriptionInfoParams {
  expiresDate?: DateOrString | null | void;
  isPro: boolean;
  maxActiveCompetitions: number;
  originalTransactionId?: string | null | void;
  userId: Buffer;
}

/** 'UpdateUserSubscriptionInfo' return type */
export type IUpdateUserSubscriptionInfoResult = void;

/** 'UpdateUserSubscriptionInfo' query type */
export interface IUpdateUserSubscriptionInfoQuery {
  params: IUpdateUserSubscriptionInfoParams;
  result: IUpdateUserSubscriptionInfoResult;
}

const updateUserSubscriptionInfoIR: any = {"usedParamSet":{"isPro":true,"maxActiveCompetitions":true,"originalTransactionId":true,"expiresDate":true,"userId":true},"params":[{"name":"isPro","required":true,"transform":{"type":"scalar"},"locs":[{"a":26,"b":32}]},{"name":"maxActiveCompetitions","required":true,"transform":{"type":"scalar"},"locs":[{"a":61,"b":83}]},{"name":"originalTransactionId","required":false,"transform":{"type":"scalar"},"locs":[{"a":122,"b":143}]},{"name":"expiresDate","required":false,"transform":{"type":"scalar"},"locs":[{"a":174,"b":185}]},{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":203,"b":210}]}],"statement":"UPDATE users\nSET is_pro = :isPro!, max_active_competitions = :maxActiveCompetitions!,\n    apple_original_transaction_id = :originalTransactionId, subscription_expires_date = :expiresDate\nWHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 * UPDATE users
 * SET is_pro = :isPro!, max_active_competitions = :maxActiveCompetitions!,
 *     apple_original_transaction_id = :originalTransactionId, subscription_expires_date = :expiresDate
 * WHERE user_id = :userId!
 * ```
 */
export function updateUserSubscriptionInfo(params: IUpdateUserSubscriptionInfoParams): Promise<Array<IUpdateUserSubscriptionInfoResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const updateUserSubscriptionInfo = new pgtyped.PreparedQuery<IUpdateUserSubscriptionInfoParams,IUpdateUserSubscriptionInfoResult>(updateUserSubscriptionInfoIR);
    return updateUserSubscriptionInfo.run(params, DatabaseConnectionPool);
  });
}


/** 'GetUserByOriginalTransactionId' parameters type */
export interface IGetUserByOriginalTransactionIdParams {
  originalTransactionId: string;
}

/** 'GetUserByOriginalTransactionId' return type */
export interface IGetUserByOriginalTransactionIdResult {
  user_id: Buffer;
}

/** 'GetUserByOriginalTransactionId' query type */
export interface IGetUserByOriginalTransactionIdQuery {
  params: IGetUserByOriginalTransactionIdParams;
  result: IGetUserByOriginalTransactionIdResult;
}

const getUserByOriginalTransactionIdIR: any = {"usedParamSet":{"originalTransactionId":true},"params":[{"name":"originalTransactionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":64,"b":86}]}],"statement":"SELECT user_id FROM users WHERE apple_original_transaction_id = :originalTransactionId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT user_id FROM users WHERE apple_original_transaction_id = :originalTransactionId!
 * ```
 */
export function getUserByOriginalTransactionId(params: IGetUserByOriginalTransactionIdParams): Promise<Array<IGetUserByOriginalTransactionIdResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getUserByOriginalTransactionId = new pgtyped.PreparedQuery<IGetUserByOriginalTransactionIdParams,IGetUserByOriginalTransactionIdResult>(getUserByOriginalTransactionIdIR);
    return getUserByOriginalTransactionId.run(params, DatabaseConnectionPool);
  });
}


/** 'DeleteUser' parameters type */
export interface IDeleteUserParams {
  userId: Buffer;
}

/** 'DeleteUser' return type */
export type IDeleteUserResult = void;

/** 'DeleteUser' query type */
export interface IDeleteUserQuery {
  params: IDeleteUserParams;
  result: IDeleteUserResult;
}

const deleteUserIR: any = {"usedParamSet":{"userId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":34,"b":41}]}],"statement":"DELETE FROM users WHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 * DELETE FROM users WHERE user_id = :userId!
 * ```
 */
export function deleteUser(params: IDeleteUserParams): Promise<Array<IDeleteUserResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const deleteUser = new pgtyped.PreparedQuery<IDeleteUserParams,IDeleteUserResult>(deleteUserIR);
    return deleteUser.run(params, DatabaseConnectionPool);
  });
}


/** 'CreateBotUser' parameters type */
export interface ICreateBotUserParams {
  createdDate: DateOrString;
  firstName: string;
  isPro: boolean;
  lastName?: string | null | void;
  maxActiveCompetitions: number;
  userId: Buffer;
}

/** 'CreateBotUser' return type */
export type ICreateBotUserResult = void;

/** 'CreateBotUser' query type */
export interface ICreateBotUserQuery {
  params: ICreateBotUserParams;
  result: ICreateBotUserResult;
}

const createBotUserIR: any = {"usedParamSet":{"userId":true,"firstName":true,"lastName":true,"maxActiveCompetitions":true,"isPro":true,"createdDate":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":113,"b":120}]},{"name":"firstName","required":true,"transform":{"type":"scalar"},"locs":[{"a":123,"b":133}]},{"name":"lastName","required":false,"transform":{"type":"scalar"},"locs":[{"a":136,"b":144}]},{"name":"maxActiveCompetitions","required":true,"transform":{"type":"scalar"},"locs":[{"a":147,"b":169}]},{"name":"isPro","required":true,"transform":{"type":"scalar"},"locs":[{"a":172,"b":178}]},{"name":"createdDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":181,"b":193}]}],"statement":"INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date, is_bot)\nVALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!, true)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date, is_bot)
 * VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!, true)
 * ```
 */
export function createBotUser(params: ICreateBotUserParams): Promise<Array<ICreateBotUserResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const createBotUser = new pgtyped.PreparedQuery<ICreateBotUserParams,ICreateBotUserResult>(createBotUserIR);
    return createBotUser.run(params, DatabaseConnectionPool);
  });
}


/** 'GetBotUsers' parameters type */
export type IGetBotUsersParams = void;

/** 'GetBotUsers' return type */
export interface IGetBotUsersResult {
  userId: string;
}

/** 'GetBotUsers' query type */
export interface IGetBotUsersQuery {
  params: IGetBotUsersParams;
  result: IGetBotUsersResult;
}

const getBotUsersIR: any = {"usedParamSet":{},"params":[],"statement":"SELECT encode(user_id::bytea, 'hex') AS \"userId!\" FROM users WHERE is_bot = true"};

/**
 * Query generated from SQL:
 * ```
 * SELECT encode(user_id::bytea, 'hex') AS "userId!" FROM users WHERE is_bot = true
 * ```
 */
export function getBotUsers(params: IGetBotUsersParams): Promise<Array<IGetBotUsersResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getBotUsers = new pgtyped.PreparedQuery<IGetBotUsersParams,IGetBotUsersResult>(getBotUsersIR);
    return getBotUsers.run(params, DatabaseConnectionPool);
  });
}


/** 'GetBotUserCount' parameters type */
export type IGetBotUserCountParams = void;

/** 'GetBotUserCount' return type */
export interface IGetBotUserCountResult {
  count: number;
}

/** 'GetBotUserCount' query type */
export interface IGetBotUserCountQuery {
  params: IGetBotUserCountParams;
  result: IGetBotUserCountResult;
}

const getBotUserCountIR: any = {"usedParamSet":{},"params":[],"statement":"SELECT COUNT(*)::INTEGER AS \"count!\" FROM users WHERE is_bot = true"};

/**
 * Query generated from SQL:
 * ```
 * SELECT COUNT(*)::INTEGER AS "count!" FROM users WHERE is_bot = true
 * ```
 */
export function getBotUserCount(params: IGetBotUserCountParams): Promise<Array<IGetBotUserCountResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getBotUserCount = new pgtyped.PreparedQuery<IGetBotUserCountParams,IGetBotUserCountResult>(getBotUserCountIR);
    return getBotUserCount.run(params, DatabaseConnectionPool);
  });
}


