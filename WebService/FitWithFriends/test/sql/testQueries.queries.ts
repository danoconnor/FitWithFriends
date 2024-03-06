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


