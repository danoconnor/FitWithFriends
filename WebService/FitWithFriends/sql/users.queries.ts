/** Types generated for queries found in "sql/users.sql" */
import { PreparedQuery } from '@pgtyped/runtime';

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
export const createUser = new PreparedQuery<ICreateUserParams,ICreateUserResult>(createUserIR);


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
export const getUserName = new PreparedQuery<IGetUserNameParams,IGetUserNameResult>(getUserNameIR);


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
export const getUserMaxCompetitions = new PreparedQuery<IGetUserMaxCompetitionsParams,IGetUserMaxCompetitionsResult>(getUserMaxCompetitionsIR);


/** 'GetUsersInCompetition' parameters type */
export interface IGetUsersInCompetitionParams {
  competitionId: string;
}

/** 'GetUsersInCompetition' return type */
export interface IGetUsersInCompetitionResult {
  first_name: string;
  last_name: string | null;
  userId: string;
}

/** 'GetUsersInCompetition' query type */
export interface IGetUsersInCompetitionQuery {
  params: IGetUsersInCompetitionParams;
  result: IGetUsersInCompetitionResult;
}

const getUsersInCompetitionIR: any = {"usedParamSet":{"competitionId":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":172,"b":186}]}],"statement":"SELECT encode(userData.user_id::bytea, 'hex') AS \"userId!\", userData.first_name, userData.last_name FROM\n    (SELECT user_id FROM users_competitions WHERE competition_id = :competitionId!) AS usersCompetitions\n    INNER JOIN (SELECT user_id, first_name, last_name FROM users) as userData\n    ON usersCompetitions.user_id = userData.user_id"};

/**
 * Query generated from SQL:
 * ```
 * SELECT encode(userData.user_id::bytea, 'hex') AS "userId!", userData.first_name, userData.last_name FROM
 *     (SELECT user_id FROM users_competitions WHERE competition_id = :competitionId!) AS usersCompetitions
 *     INNER JOIN (SELECT user_id, first_name, last_name FROM users) as userData
 *     ON usersCompetitions.user_id = userData.user_id
 * ```
 */
export const getUsersInCompetition = new PreparedQuery<IGetUsersInCompetitionParams,IGetUsersInCompetitionResult>(getUsersInCompetitionIR);


