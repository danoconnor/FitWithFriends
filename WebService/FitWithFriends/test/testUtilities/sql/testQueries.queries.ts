/** Types generated for queries found in "test/testUtilities/sql/testQueries.sql" */
import { DatabaseConnectionPool } from '../../../utilities/database';

export type DateOrString = Date | string;

export type Json = null | boolean | number | string | Json[] | { [key: string]: Json };

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
  apple_original_transaction_id: string | null;
  created_date: Date;
  first_name: string;
  is_bot: boolean;
  is_pro: boolean;
  last_name: string | null;
  max_active_competitions: number;
  subscription_expires_date: Date | null;
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
  distance_walking_running_meters: number;
  exercise_time: number;
  exercise_time_goal: number;
  flights_climbed: number;
  stand_time: number;
  stand_time_goal: number;
  step_count: number;
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
  distanceWalkingRunningMeters?: number | null | void;
  exerciseTime: number;
  exerciseTimeGoal: number;
  flightsClimbed?: number | null | void;
  standTime: number;
  standTimeGoal: number;
  stepCount?: number | null | void;
  userId: Buffer;
}

/** 'InsertActivitySummary' return type */
export type IInsertActivitySummaryResult = void;

/** 'InsertActivitySummary' query type */
export interface IInsertActivitySummaryQuery {
  params: IInsertActivitySummaryParams;
  result: IInsertActivitySummaryResult;
}

const insertActivitySummaryIR: any = {"usedParamSet":{"userId":true,"date":true,"caloriesBurned":true,"caloriesGoal":true,"exerciseTime":true,"exerciseTimeGoal":true,"standTime":true,"standTimeGoal":true,"stepCount":true,"distanceWalkingRunningMeters":true,"flightsClimbed":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":212,"b":219}]},{"name":"date","required":true,"transform":{"type":"scalar"},"locs":[{"a":222,"b":227}]},{"name":"caloriesBurned","required":true,"transform":{"type":"scalar"},"locs":[{"a":230,"b":245}]},{"name":"caloriesGoal","required":true,"transform":{"type":"scalar"},"locs":[{"a":248,"b":261}]},{"name":"exerciseTime","required":true,"transform":{"type":"scalar"},"locs":[{"a":264,"b":277}]},{"name":"exerciseTimeGoal","required":true,"transform":{"type":"scalar"},"locs":[{"a":280,"b":297}]},{"name":"standTime","required":true,"transform":{"type":"scalar"},"locs":[{"a":300,"b":310}]},{"name":"standTimeGoal","required":true,"transform":{"type":"scalar"},"locs":[{"a":313,"b":327}]},{"name":"stepCount","required":false,"transform":{"type":"scalar"},"locs":[{"a":339,"b":348}]},{"name":"distanceWalkingRunningMeters","required":false,"transform":{"type":"scalar"},"locs":[{"a":364,"b":392}]},{"name":"flightsClimbed","required":false,"transform":{"type":"scalar"},"locs":[{"a":408,"b":422}]}],"statement":"INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal, step_count, distance_walking_running_meters, flights_climbed)\nVALUES (:userId!, :date!, :caloriesBurned!, :caloriesGoal!, :exerciseTime!, :exerciseTimeGoal!, :standTime!, :standTimeGoal!, COALESCE(:stepCount, 0), COALESCE(:distanceWalkingRunningMeters, 0), COALESCE(:flightsClimbed, 0))\nON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal, step_count = EXCLUDED.step_count, distance_walking_running_meters = EXCLUDED.distance_walking_running_meters, flights_climbed = EXCLUDED.flights_climbed"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal, step_count, distance_walking_running_meters, flights_climbed)
 * VALUES (:userId!, :date!, :caloriesBurned!, :caloriesGoal!, :exerciseTime!, :exerciseTimeGoal!, :standTime!, :standTimeGoal!, COALESCE(:stepCount, 0), COALESCE(:distanceWalkingRunningMeters, 0), COALESCE(:flightsClimbed, 0))
 * ON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal, step_count = EXCLUDED.step_count, distance_walking_running_meters = EXCLUDED.distance_walking_running_meters, flights_climbed = EXCLUDED.flights_climbed
 * ```
 */
export function insertActivitySummary(params: IInsertActivitySummaryParams): Promise<Array<IInsertActivitySummaryResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const insertActivitySummary = new pgtyped.PreparedQuery<IInsertActivitySummaryParams,IInsertActivitySummaryResult>(insertActivitySummaryIR);
    return insertActivitySummary.run(params, DatabaseConnectionPool);
  });
}


/** 'InsertWorkout' parameters type */
export interface IInsertWorkoutParams {
  caloriesBurned: number;
  distance?: number | null | void;
  duration: number;
  startDate: DateOrString;
  unit?: number | null | void;
  userId: Buffer;
  workoutType: number;
}

/** 'InsertWorkout' return type */
export type IInsertWorkoutResult = void;

/** 'InsertWorkout' query type */
export interface IInsertWorkoutQuery {
  params: IInsertWorkoutParams;
  result: IInsertWorkoutResult;
}

const insertWorkoutIR: any = {"usedParamSet":{"userId":true,"startDate":true,"caloriesBurned":true,"workoutType":true,"duration":true,"distance":true,"unit":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":108,"b":115}]},{"name":"startDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":118,"b":128}]},{"name":"caloriesBurned","required":true,"transform":{"type":"scalar"},"locs":[{"a":131,"b":146}]},{"name":"workoutType","required":true,"transform":{"type":"scalar"},"locs":[{"a":149,"b":161}]},{"name":"duration","required":true,"transform":{"type":"scalar"},"locs":[{"a":164,"b":173}]},{"name":"distance","required":false,"transform":{"type":"scalar"},"locs":[{"a":176,"b":184}]},{"name":"unit","required":false,"transform":{"type":"scalar"},"locs":[{"a":187,"b":191}]}],"statement":"INSERT INTO workouts (user_id, start_date, calories_burned, workout_type, duration, distance, unit)\nVALUES (:userId!, :startDate!, :caloriesBurned!, :workoutType!, :duration!, :distance, :unit)\nON CONFLICT (user_id, start_date, workout_type) DO NOTHING"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO workouts (user_id, start_date, calories_burned, workout_type, duration, distance, unit)
 * VALUES (:userId!, :startDate!, :caloriesBurned!, :workoutType!, :duration!, :distance, :unit)
 * ON CONFLICT (user_id, start_date, workout_type) DO NOTHING
 * ```
 */
export function insertWorkout(params: IInsertWorkoutParams): Promise<Array<IInsertWorkoutResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const insertWorkout = new pgtyped.PreparedQuery<IInsertWorkoutParams,IInsertWorkoutResult>(insertWorkoutIR);
    return insertWorkout.run(params, DatabaseConnectionPool);
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
  scoringRules?: Json | null | void;
  startDate: DateOrString;
}

/** 'CreateCompetition' return type */
export type ICreateCompetitionResult = void;

/** 'CreateCompetition' query type */
export interface ICreateCompetitionQuery {
  params: ICreateCompetitionParams;
  result: ICreateCompetitionResult;
}

const createCompetitionIR: any = {"usedParamSet":{"startDate":true,"endDate":true,"displayName":true,"adminUserId":true,"accessToken":true,"ianaTimezone":true,"competitionId":true,"scoringRules":true},"params":[{"name":"startDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":145,"b":155}]},{"name":"endDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":158,"b":166}]},{"name":"displayName","required":true,"transform":{"type":"scalar"},"locs":[{"a":169,"b":181}]},{"name":"adminUserId","required":true,"transform":{"type":"scalar"},"locs":[{"a":184,"b":196}]},{"name":"accessToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":199,"b":211}]},{"name":"ianaTimezone","required":true,"transform":{"type":"scalar"},"locs":[{"a":214,"b":227}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":230,"b":244}]},{"name":"scoringRules","required":false,"transform":{"type":"scalar"},"locs":[{"a":247,"b":259}]}],"statement":"INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, scoring_rules)\nVALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!, :scoringRules)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, scoring_rules)
 * VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!, :scoringRules)
 * ```
 */
export function createCompetition(params: ICreateCompetitionParams): Promise<Array<ICreateCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const createCompetition = new pgtyped.PreparedQuery<ICreateCompetitionParams,ICreateCompetitionResult>(createCompetitionIR);
    return createCompetition.run(params, DatabaseConnectionPool);
  });
}


/** 'CreateCompetitionWithState' parameters type */
export interface ICreateCompetitionWithStateParams {
  accessToken: string;
  adminUserId: Buffer;
  competitionId: string;
  displayName: string;
  endDate: DateOrString;
  ianaTimezone: string;
  scoringRules?: Json | null | void;
  startDate: DateOrString;
  state: number;
}

/** 'CreateCompetitionWithState' return type */
export type ICreateCompetitionWithStateResult = void;

/** 'CreateCompetitionWithState' query type */
export interface ICreateCompetitionWithStateQuery {
  params: ICreateCompetitionWithStateParams;
  result: ICreateCompetitionWithStateResult;
}

const createCompetitionWithStateIR: any = {"usedParamSet":{"startDate":true,"endDate":true,"displayName":true,"adminUserId":true,"accessToken":true,"ianaTimezone":true,"competitionId":true,"state":true,"scoringRules":true},"params":[{"name":"startDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":152,"b":162}]},{"name":"endDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":165,"b":173}]},{"name":"displayName","required":true,"transform":{"type":"scalar"},"locs":[{"a":176,"b":188}]},{"name":"adminUserId","required":true,"transform":{"type":"scalar"},"locs":[{"a":191,"b":203}]},{"name":"accessToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":206,"b":218}]},{"name":"ianaTimezone","required":true,"transform":{"type":"scalar"},"locs":[{"a":221,"b":234}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":237,"b":251}]},{"name":"state","required":true,"transform":{"type":"scalar"},"locs":[{"a":254,"b":260}]},{"name":"scoringRules","required":false,"transform":{"type":"scalar"},"locs":[{"a":263,"b":275}]}],"statement":"INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, state, scoring_rules)\nVALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!, :state!, :scoringRules)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, state, scoring_rules)
 * VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!, :state!, :scoringRules)
 * ```
 */
export function createCompetitionWithState(params: ICreateCompetitionWithStateParams): Promise<Array<ICreateCompetitionWithStateResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const createCompetitionWithState = new pgtyped.PreparedQuery<ICreateCompetitionWithStateParams,ICreateCompetitionWithStateResult>(createCompetitionWithStateIR);
    return createCompetitionWithState.run(params, DatabaseConnectionPool);
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


/** 'UpdateUserCompetitionFinalPoints' parameters type */
export interface IUpdateUserCompetitionFinalPointsParams {
  competitionId: string;
  finalPoints: number;
  userId: Buffer;
}

/** 'UpdateUserCompetitionFinalPoints' return type */
export type IUpdateUserCompetitionFinalPointsResult = void;

/** 'UpdateUserCompetitionFinalPoints' query type */
export interface IUpdateUserCompetitionFinalPointsQuery {
  params: IUpdateUserCompetitionFinalPointsParams;
  result: IUpdateUserCompetitionFinalPointsResult;
}

const updateUserCompetitionFinalPointsIR: any = {"usedParamSet":{"finalPoints":true,"userId":true,"competitionId":true},"params":[{"name":"finalPoints","required":true,"transform":{"type":"scalar"},"locs":[{"a":46,"b":58}]},{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":77,"b":84}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":107,"b":121}]}],"statement":"UPDATE users_competitions \nSET final_points = :finalPoints! \nWHERE user_id = :userId! AND competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 * UPDATE users_competitions 
 * SET final_points = :finalPoints! 
 * WHERE user_id = :userId! AND competition_id = :competitionId!
 * ```
 */
export function updateUserCompetitionFinalPoints(params: IUpdateUserCompetitionFinalPointsParams): Promise<Array<IUpdateUserCompetitionFinalPointsResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const updateUserCompetitionFinalPoints = new pgtyped.PreparedQuery<IUpdateUserCompetitionFinalPointsParams,IUpdateUserCompetitionFinalPointsResult>(updateUserCompetitionFinalPointsIR);
    return updateUserCompetitionFinalPoints.run(params, DatabaseConnectionPool);
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
  is_public: boolean;
  scoring_rules: Json | null;
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
  final_points: number | null;
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


/** 'GetRefreshTokens' parameters type */
export type IGetRefreshTokensParams = void;

/** 'GetRefreshTokens' return type */
export interface IGetRefreshTokensResult {
  client_id: string;
  refresh_token: string;
  refresh_token_expires_on: Date;
  user_id: Buffer;
}

/** 'GetRefreshTokens' query type */
export interface IGetRefreshTokensQuery {
  params: IGetRefreshTokensParams;
  result: IGetRefreshTokensResult;
}

const getRefreshTokensIR: any = {"usedParamSet":{},"params":[],"statement":"SELECT * FROM oauth_tokens"};

/**
 * Query generated from SQL:
 * ```
 * SELECT * FROM oauth_tokens
 * ```
 */
export function getRefreshTokens(params: IGetRefreshTokensParams): Promise<Array<IGetRefreshTokensResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getRefreshTokens = new pgtyped.PreparedQuery<IGetRefreshTokensParams,IGetRefreshTokensResult>(getRefreshTokensIR);
    return getRefreshTokens.run(params, DatabaseConnectionPool);
  });
}


/** 'DeleteAllRefreshTokens' parameters type */
export type IDeleteAllRefreshTokensParams = void;

/** 'DeleteAllRefreshTokens' return type */
export type IDeleteAllRefreshTokensResult = void;

/** 'DeleteAllRefreshTokens' query type */
export interface IDeleteAllRefreshTokensQuery {
  params: IDeleteAllRefreshTokensParams;
  result: IDeleteAllRefreshTokensResult;
}

const deleteAllRefreshTokensIR: any = {"usedParamSet":{},"params":[],"statement":"DELETE FROM oauth_tokens"};

/**
 * Query generated from SQL:
 * ```
 * DELETE FROM oauth_tokens
 * ```
 */
export function deleteAllRefreshTokens(params: IDeleteAllRefreshTokensParams): Promise<Array<IDeleteAllRefreshTokensResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const deleteAllRefreshTokens = new pgtyped.PreparedQuery<IDeleteAllRefreshTokensParams,IDeleteAllRefreshTokensResult>(deleteAllRefreshTokensIR);
    return deleteAllRefreshTokens.run(params, DatabaseConnectionPool);
  });
}


/** 'CreatePushToken' parameters type */
export interface ICreatePushTokenParams {
  appInstallId: string;
  platform: number;
  pushToken: string;
  userId: Buffer;
}

/** 'CreatePushToken' return type */
export type ICreatePushTokenResult = void;

/** 'CreatePushToken' query type */
export interface ICreatePushTokenQuery {
  params: ICreatePushTokenParams;
  result: ICreatePushTokenResult;
}

const createPushTokenIR: any = {"usedParamSet":{"userId":true,"pushToken":true,"platform":true,"appInstallId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":80,"b":87}]},{"name":"pushToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":90,"b":100}]},{"name":"platform","required":true,"transform":{"type":"scalar"},"locs":[{"a":103,"b":112}]},{"name":"appInstallId","required":true,"transform":{"type":"scalar"},"locs":[{"a":115,"b":128}]}],"statement":"INSERT INTO push_tokens (user_id, push_token, platform, app_install_id)\nVALUES (:userId!, :pushToken!, :platform!, :appInstallId!)\nON CONFLICT (user_id, platform, app_install_id) DO UPDATE SET push_token = EXCLUDED.push_token"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO push_tokens (user_id, push_token, platform, app_install_id)
 * VALUES (:userId!, :pushToken!, :platform!, :appInstallId!)
 * ON CONFLICT (user_id, platform, app_install_id) DO UPDATE SET push_token = EXCLUDED.push_token
 * ```
 */
export function createPushToken(params: ICreatePushTokenParams): Promise<Array<ICreatePushTokenResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const createPushToken = new pgtyped.PreparedQuery<ICreatePushTokenParams,ICreatePushTokenResult>(createPushTokenIR);
    return createPushToken.run(params, DatabaseConnectionPool);
  });
}


/** 'CreatePublicCompetition' parameters type */
export interface ICreatePublicCompetitionParams {
  accessToken: string;
  adminUserId: Buffer;
  competitionId: string;
  displayName: string;
  endDate: DateOrString;
  ianaTimezone: string;
  startDate: DateOrString;
}

/** 'CreatePublicCompetition' return type */
export type ICreatePublicCompetitionResult = void;

/** 'CreatePublicCompetition' query type */
export interface ICreatePublicCompetitionQuery {
  params: ICreatePublicCompetitionParams;
  result: ICreatePublicCompetitionResult;
}

const createPublicCompetitionIR: any = {"usedParamSet":{"startDate":true,"endDate":true,"displayName":true,"adminUserId":true,"accessToken":true,"ianaTimezone":true,"competitionId":true},"params":[{"name":"startDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":141,"b":151}]},{"name":"endDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":154,"b":162}]},{"name":"displayName","required":true,"transform":{"type":"scalar"},"locs":[{"a":165,"b":177}]},{"name":"adminUserId","required":true,"transform":{"type":"scalar"},"locs":[{"a":180,"b":192}]},{"name":"accessToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":195,"b":207}]},{"name":"ianaTimezone","required":true,"transform":{"type":"scalar"},"locs":[{"a":210,"b":223}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":226,"b":240}]}],"statement":"INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, is_public)\nVALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!, true)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, is_public)
 * VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!, true)
 * ```
 */
export function createPublicCompetition(params: ICreatePublicCompetitionParams): Promise<Array<ICreatePublicCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const createPublicCompetition = new pgtyped.PreparedQuery<ICreatePublicCompetitionParams,ICreatePublicCompetitionResult>(createPublicCompetitionIR);
    return createPublicCompetition.run(params, DatabaseConnectionPool);
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


/** 'UpdateCompetitionState' parameters type */
export interface IUpdateCompetitionStateParams {
  competitionId: string;
  state: number;
}

/** 'UpdateCompetitionState' return type */
export type IUpdateCompetitionStateResult = void;

/** 'UpdateCompetitionState' query type */
export interface IUpdateCompetitionStateQuery {
  params: IUpdateCompetitionStateParams;
  result: IUpdateCompetitionStateResult;
}

const updateCompetitionStateIR: any = {"usedParamSet":{"state":true,"competitionId":true},"params":[{"name":"state","required":true,"transform":{"type":"scalar"},"locs":[{"a":32,"b":38}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":63,"b":77}]}],"statement":"UPDATE competitions SET state = :state! WHERE competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 * UPDATE competitions SET state = :state! WHERE competition_id = :competitionId!
 * ```
 */
export function updateCompetitionState(params: IUpdateCompetitionStateParams): Promise<Array<IUpdateCompetitionStateResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const updateCompetitionState = new pgtyped.PreparedQuery<IUpdateCompetitionStateParams,IUpdateCompetitionStateResult>(updateCompetitionStateIR);
    return updateCompetitionState.run(params, DatabaseConnectionPool);
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


