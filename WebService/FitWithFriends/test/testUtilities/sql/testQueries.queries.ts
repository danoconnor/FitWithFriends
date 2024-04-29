/** Types generated for queries found in "test/testUtilities/sql/testQueries.sql" */
import { DatabaseConnectionPool } from '../../../utilities/database';

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


/** 'ClearDataForUser' parameters type */
export interface IClearDataForUserParams {
  userId: Buffer;
}

/** 'ClearDataForUser' return type */
export type IClearDataForUserResult = void;

/** 'ClearDataForUser' query type */
export interface IClearDataForUserQuery {
  params: IClearDataForUserParams;
  result: IClearDataForUserResult;
}

const clearDataForUserIR: any = {"usedParamSet":{"userId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":188,"b":195}]}],"statement":"                                                                                                                                                         \nDELETE FROM users WHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 *                                                                                                                                                          
 * DELETE FROM users WHERE user_id = :userId!
 * ```
 */
export function clearDataForUser(params: IClearDataForUserParams): Promise<Array<IClearDataForUserResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const clearDataForUser = new pgtyped.PreparedQuery<IClearDataForUserParams,IClearDataForUserResult>(clearDataForUserIR);
    return clearDataForUser.run(params, DatabaseConnectionPool);
  });
}


/** 'ClearDataForCompetition' parameters type */
export interface IClearDataForCompetitionParams {
  competitionId: string;
}

/** 'ClearDataForCompetition' return type */
export type IClearDataForCompetitionResult = void;

/** 'ClearDataForCompetition' query type */
export interface IClearDataForCompetitionQuery {
  params: IClearDataForCompetitionParams;
  result: IClearDataForCompetitionResult;
}

const clearDataForCompetitionIR: any = {"usedParamSet":{"competitionId":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":176,"b":190}]}],"statement":"                                                                                                                               \nDELETE FROM competitions WHERE competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 *                                                                                                                                
 * DELETE FROM competitions WHERE competition_id = :competitionId!
 * ```
 */
export function clearDataForCompetition(params: IClearDataForCompetitionParams): Promise<Array<IClearDataForCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const clearDataForCompetition = new pgtyped.PreparedQuery<IClearDataForCompetitionParams,IClearDataForCompetitionResult>(clearDataForCompetitionIR);
    return clearDataForCompetition.run(params, DatabaseConnectionPool);
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


/** 'InsertActivitySummary' parameters type */
export interface IInsertActivitySummaryParams {
  caloriesBurned: number;
  caloriesGoal: number;
  date: DateOrString;
  exerciseTime: number;
  exerciseTimeGoal: number;
  standTime: number;
  standTimeGoal: number;
  userId: Buffer;
}

/** 'InsertActivitySummary' return type */
export type IInsertActivitySummaryResult = void;

/** 'InsertActivitySummary' query type */
export interface IInsertActivitySummaryQuery {
  params: IInsertActivitySummaryParams;
  result: IInsertActivitySummaryResult;
}

const insertActivitySummaryIR: any = {"usedParamSet":{"userId":true,"date":true,"caloriesBurned":true,"caloriesGoal":true,"exerciseTime":true,"exerciseTimeGoal":true,"standTime":true,"standTimeGoal":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":150,"b":157}]},{"name":"date","required":true,"transform":{"type":"scalar"},"locs":[{"a":160,"b":165}]},{"name":"caloriesBurned","required":true,"transform":{"type":"scalar"},"locs":[{"a":168,"b":183}]},{"name":"caloriesGoal","required":true,"transform":{"type":"scalar"},"locs":[{"a":186,"b":199}]},{"name":"exerciseTime","required":true,"transform":{"type":"scalar"},"locs":[{"a":202,"b":215}]},{"name":"exerciseTimeGoal","required":true,"transform":{"type":"scalar"},"locs":[{"a":218,"b":235}]},{"name":"standTime","required":true,"transform":{"type":"scalar"},"locs":[{"a":238,"b":248}]},{"name":"standTimeGoal","required":true,"transform":{"type":"scalar"},"locs":[{"a":251,"b":265}]}],"statement":"INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal)\nVALUES (:userId!, :date!, :caloriesBurned!, :caloriesGoal!, :exerciseTime!, :exerciseTimeGoal!, :standTime!, :standTimeGoal!)\nON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal)
 * VALUES (:userId!, :date!, :caloriesBurned!, :caloriesGoal!, :exerciseTime!, :exerciseTimeGoal!, :standTime!, :standTimeGoal!)
 * ON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal
 * ```
 */
export function insertActivitySummary(params: IInsertActivitySummaryParams): Promise<Array<IInsertActivitySummaryResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const insertActivitySummary = new pgtyped.PreparedQuery<IInsertActivitySummaryParams,IInsertActivitySummaryResult>(insertActivitySummaryIR);
    return insertActivitySummary.run(params, DatabaseConnectionPool);
  });
}


/** 'CreateCompetition' parameters type */
export interface ICreateCompetitionParams {
  accessToken: string;
  adminUserId: Buffer;
  competitionId: string;
  displayName: string;
  endDate: DateOrString;
  ianaTimezone: string;
  startDate: DateOrString;
}

/** 'CreateCompetition' return type */
export type ICreateCompetitionResult = void;

/** 'CreateCompetition' query type */
export interface ICreateCompetitionQuery {
  params: ICreateCompetitionParams;
  result: ICreateCompetitionResult;
}

const createCompetitionIR: any = {"usedParamSet":{"startDate":true,"endDate":true,"displayName":true,"adminUserId":true,"accessToken":true,"ianaTimezone":true,"competitionId":true},"params":[{"name":"startDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":131,"b":141}]},{"name":"endDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":144,"b":152}]},{"name":"displayName","required":true,"transform":{"type":"scalar"},"locs":[{"a":155,"b":167}]},{"name":"adminUserId","required":true,"transform":{"type":"scalar"},"locs":[{"a":170,"b":182}]},{"name":"accessToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":185,"b":197}]},{"name":"ianaTimezone","required":true,"transform":{"type":"scalar"},"locs":[{"a":200,"b":213}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":216,"b":230}]}],"statement":"INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id) \nVALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id) 
 * VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!)
 * ```
 */
export function createCompetition(params: ICreateCompetitionParams): Promise<Array<ICreateCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const createCompetition = new pgtyped.PreparedQuery<ICreateCompetitionParams,ICreateCompetitionResult>(createCompetitionIR);
    return createCompetition.run(params, DatabaseConnectionPool);
  });
}


/** 'AddUserToCompetition' parameters type */
export interface IAddUserToCompetitionParams {
  competitionId: string;
  userId: Buffer;
}

/** 'AddUserToCompetition' return type */
export type IAddUserToCompetitionResult = void;

/** 'AddUserToCompetition' query type */
export interface IAddUserToCompetitionQuery {
  params: IAddUserToCompetitionParams;
  result: IAddUserToCompetitionResult;
}

const addUserToCompetitionIR: any = {"usedParamSet":{"userId":true,"competitionId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":65,"b":72}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":75,"b":89}]}],"statement":"INSERT INTO users_competitions (user_id, competition_id)\nVALUES (:userId!, :competitionId!)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO users_competitions (user_id, competition_id)
 * VALUES (:userId!, :competitionId!)
 * ```
 */
export function addUserToCompetition(params: IAddUserToCompetitionParams): Promise<Array<IAddUserToCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const addUserToCompetition = new pgtyped.PreparedQuery<IAddUserToCompetitionParams,IAddUserToCompetitionResult>(addUserToCompetitionIR);
    return addUserToCompetition.run(params, DatabaseConnectionPool);
  });
}


/** 'GetCompetition' parameters type */
export interface IGetCompetitionParams {
  competitionId: string;
}

/** 'GetCompetition' return type */
export interface IGetCompetitionResult {
  access_token: string;
  admin_user_id: Buffer;
  competition_id: string;
  display_name: string;
  end_date: Date;
  iana_timezone: string;
  start_date: Date;
  state: number;
}

/** 'GetCompetition' query type */
export interface IGetCompetitionQuery {
  params: IGetCompetitionParams;
  result: IGetCompetitionResult;
}

const getCompetitionIR: any = {"usedParamSet":{"competitionId":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":50,"b":64}]}],"statement":"SELECT * FROM competitions WHERE competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT * FROM competitions WHERE competition_id = :competitionId!
 * ```
 */
export function getCompetition(params: IGetCompetitionParams): Promise<Array<IGetCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getCompetition = new pgtyped.PreparedQuery<IGetCompetitionParams,IGetCompetitionResult>(getCompetitionIR);
    return getCompetition.run(params, DatabaseConnectionPool);
  });
}


/** 'GetUsersInCompetition' parameters type */
export interface IGetUsersInCompetitionParams {
  competitionId: string;
}

/** 'GetUsersInCompetition' return type */
export interface IGetUsersInCompetitionResult {
  competition_id: string;
  user_id: Buffer;
}

/** 'GetUsersInCompetition' query type */
export interface IGetUsersInCompetitionQuery {
  params: IGetUsersInCompetitionParams;
  result: IGetUsersInCompetitionResult;
}

const getUsersInCompetitionIR: any = {"usedParamSet":{"competitionId":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":56,"b":70}]}],"statement":"SELECT * FROM users_competitions WHERE competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT * FROM users_competitions WHERE competition_id = :competitionId!
 * ```
 */
export function getUsersInCompetition(params: IGetUsersInCompetitionParams): Promise<Array<IGetUsersInCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getUsersInCompetition = new pgtyped.PreparedQuery<IGetUsersInCompetitionParams,IGetUsersInCompetitionResult>(getUsersInCompetitionIR);
    return getUsersInCompetition.run(params, DatabaseConnectionPool);
  });
}


/** 'GetPushTokenForUser' parameters type */
export interface IGetPushTokenForUserParams {
  userId: Buffer;
}

/** 'GetPushTokenForUser' return type */
export interface IGetPushTokenForUserResult {
  app_install_id: string;
  platform: number;
  push_token: string;
  user_id: Buffer;
}

/** 'GetPushTokenForUser' query type */
export interface IGetPushTokenForUserQuery {
  params: IGetPushTokenForUserParams;
  result: IGetPushTokenForUserResult;
}

const getPushTokenForUserIR: any = {"usedParamSet":{"userId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":42,"b":49}]}],"statement":"SELECT * FROM push_tokens WHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT * FROM push_tokens WHERE user_id = :userId!
 * ```
 */
export function getPushTokenForUser(params: IGetPushTokenForUserParams): Promise<Array<IGetPushTokenForUserResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getPushTokenForUser = new pgtyped.PreparedQuery<IGetPushTokenForUserParams,IGetPushTokenForUserResult>(getPushTokenForUserIR);
    return getPushTokenForUser.run(params, DatabaseConnectionPool);
  });
}


/** 'GetWorkoutsForUser' parameters type */
export interface IGetWorkoutsForUserParams {
  userId: Buffer;
}

/** 'GetWorkoutsForUser' return type */
export interface IGetWorkoutsForUserResult {
  calories_burned: number;
  distance: number | null;
  duration: number;
  start_date: Date;
  unit: number | null;
  user_id: Buffer;
  workout_type: number;
}

/** 'GetWorkoutsForUser' query type */
export interface IGetWorkoutsForUserQuery {
  params: IGetWorkoutsForUserParams;
  result: IGetWorkoutsForUserResult;
}

const getWorkoutsForUserIR: any = {"usedParamSet":{"userId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":39,"b":46}]}],"statement":"SELECT * FROM workouts WHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT * FROM workouts WHERE user_id = :userId!
 * ```
 */
export function getWorkoutsForUser(params: IGetWorkoutsForUserParams): Promise<Array<IGetWorkoutsForUserResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getWorkoutsForUser = new pgtyped.PreparedQuery<IGetWorkoutsForUserParams,IGetWorkoutsForUserResult>(getWorkoutsForUserIR);
    return getWorkoutsForUser.run(params, DatabaseConnectionPool);
  });
}


