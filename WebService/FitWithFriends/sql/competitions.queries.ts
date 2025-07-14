/** Types generated for queries found in "sql/competitions.sql" */
import { DatabaseConnectionPool } from '../utilities/database';

export type DateOrString = Date | string;

/** 'GetUsersCompetitions' parameters type */
export interface IGetUsersCompetitionsParams {
  userId: Buffer;
}

/** 'GetUsersCompetitions' return type */
export interface IGetUsersCompetitionsResult {
  competition_id: string;
}

/** 'GetUsersCompetitions' query type */
export interface IGetUsersCompetitionsQuery {
  params: IGetUsersCompetitionsParams;
  result: IGetUsersCompetitionsResult;
}

const getUsersCompetitionsIR: any = {"usedParamSet":{"userId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":62,"b":69}]}],"statement":"SELECT competition_id from users_competitions WHERE user_id = :userId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT competition_id from users_competitions WHERE user_id = :userId!
 * ```
 */
export function getUsersCompetitions(params: IGetUsersCompetitionsParams): Promise<Array<IGetUsersCompetitionsResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getUsersCompetitions = new pgtyped.PreparedQuery<IGetUsersCompetitionsParams,IGetUsersCompetitionsResult>(getUsersCompetitionsIR);
    return getUsersCompetitions.run(params, DatabaseConnectionPool);
  });
}


/** 'GetUsersForCompetition' parameters type */
export interface IGetUsersForCompetitionParams {
  competitionId: string;
}

/** 'GetUsersForCompetition' return type */
export interface IGetUsersForCompetitionResult {
  final_points: number | null;
  user_id: Buffer;
}

/** 'GetUsersForCompetition' query type */
export interface IGetUsersForCompetitionQuery {
  params: IGetUsersForCompetitionParams;
  result: IGetUsersForCompetitionResult;
}

const getUsersForCompetitionIR: any = {"usedParamSet":{"competitionId":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":76,"b":90}]}],"statement":"SELECT user_id, final_points FROM users_competitions WHERE competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT user_id, final_points FROM users_competitions WHERE competition_id = :competitionId!
 * ```
 */
export function getUsersForCompetition(params: IGetUsersForCompetitionParams): Promise<Array<IGetUsersForCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getUsersForCompetition = new pgtyped.PreparedQuery<IGetUsersForCompetitionParams,IGetUsersForCompetitionResult>(getUsersForCompetitionIR);
    return getUsersForCompetition.run(params, DatabaseConnectionPool);
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

const createCompetitionIR: any = {"usedParamSet":{"startDate":true,"endDate":true,"displayName":true,"adminUserId":true,"accessToken":true,"ianaTimezone":true,"competitionId":true},"params":[{"name":"startDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":130,"b":140}]},{"name":"endDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":143,"b":151}]},{"name":"displayName","required":true,"transform":{"type":"scalar"},"locs":[{"a":154,"b":166}]},{"name":"adminUserId","required":true,"transform":{"type":"scalar"},"locs":[{"a":169,"b":181}]},{"name":"accessToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":184,"b":196}]},{"name":"ianaTimezone","required":true,"transform":{"type":"scalar"},"locs":[{"a":199,"b":212}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":215,"b":229}]}],"statement":"INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id) VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id) VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!)
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

const addUserToCompetitionIR: any = {"usedParamSet":{"userId":true,"competitionId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":66,"b":73}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":76,"b":90}]}],"statement":"INSERT INTO users_competitions (user_id, competition_id) \nVALUES (:userId!, :competitionId!)\nON CONFLICT (user_id, competition_id) DO NOTHING"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO users_competitions (user_id, competition_id) 
 * VALUES (:userId!, :competitionId!)
 * ON CONFLICT (user_id, competition_id) DO NOTHING
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

const getCompetitionIR: any = {"usedParamSet":{"competitionId":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":223,"b":237}]}],"statement":"                                                                                      \nSELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id, state FROM competitions WHERE competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 *                                                                                       
 * SELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id, state FROM competitions WHERE competition_id = :competitionId!
 * ```
 */
export function getCompetition(params: IGetCompetitionParams): Promise<Array<IGetCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getCompetition = new pgtyped.PreparedQuery<IGetCompetitionParams,IGetCompetitionResult>(getCompetitionIR);
    return getCompetition.run(params, DatabaseConnectionPool);
  });
}


/** 'GetCompetitionAdminDetails' parameters type */
export interface IGetCompetitionAdminDetailsParams {
  adminUserId: Buffer;
  competitionId: string;
}

/** 'GetCompetitionAdminDetails' return type */
export interface IGetCompetitionAdminDetailsResult {
  access_token: string;
  admin_user_id: Buffer;
  competition_id: string;
  display_name: string;
  end_date: Date;
  iana_timezone: string;
  start_date: Date;
}

/** 'GetCompetitionAdminDetails' query type */
export interface IGetCompetitionAdminDetailsQuery {
  params: IGetCompetitionAdminDetailsParams;
  result: IGetCompetitionAdminDetailsResult;
}

const getCompetitionAdminDetailsIR: any = {"usedParamSet":{"competitionId":true,"adminUserId":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":143,"b":157}]},{"name":"adminUserId","required":true,"transform":{"type":"scalar"},"locs":[{"a":179,"b":191}]}],"statement":"SELECT start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id FROM competitions WHERE competition_id = :competitionId! AND admin_user_id = :adminUserId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id FROM competitions WHERE competition_id = :competitionId! AND admin_user_id = :adminUserId!
 * ```
 */
export function getCompetitionAdminDetails(params: IGetCompetitionAdminDetailsParams): Promise<Array<IGetCompetitionAdminDetailsResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getCompetitionAdminDetails = new pgtyped.PreparedQuery<IGetCompetitionAdminDetailsParams,IGetCompetitionAdminDetailsResult>(getCompetitionAdminDetailsIR);
    return getCompetitionAdminDetails.run(params, DatabaseConnectionPool);
  });
}


/** 'GetNumUsersInCompetition' parameters type */
export interface IGetNumUsersInCompetitionParams {
  competitionId: string;
}

/** 'GetNumUsersInCompetition' return type */
export interface IGetNumUsersInCompetitionResult {
  count: number | null;
}

/** 'GetNumUsersInCompetition' query type */
export interface IGetNumUsersInCompetitionQuery {
  params: IGetNumUsersInCompetitionParams;
  result: IGetNumUsersInCompetitionResult;
}

const getNumUsersInCompetitionIR: any = {"usedParamSet":{"competitionId":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":78,"b":92}]}],"statement":"SELECT count(user_id)::INTEGER FROM users_competitions WHERE competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT count(user_id)::INTEGER FROM users_competitions WHERE competition_id = :competitionId!
 * ```
 */
export function getNumUsersInCompetition(params: IGetNumUsersInCompetitionParams): Promise<Array<IGetNumUsersInCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getNumUsersInCompetition = new pgtyped.PreparedQuery<IGetNumUsersInCompetitionParams,IGetNumUsersInCompetitionResult>(getNumUsersInCompetitionIR);
    return getNumUsersInCompetition.run(params, DatabaseConnectionPool);
  });
}


/** 'GetCompetitionDescriptionDetails' parameters type */
export interface IGetCompetitionDescriptionDetailsParams {
  competitionAccessToken: string;
  competitionId: string;
}

/** 'GetCompetitionDescriptionDetails' return type */
export interface IGetCompetitionDescriptionDetailsResult {
  admin_user_id: Buffer;
  display_name: string;
  end_date: Date;
  start_date: Date;
}

/** 'GetCompetitionDescriptionDetails' query type */
export interface IGetCompetitionDescriptionDetailsQuery {
  params: IGetCompetitionDescriptionDetailsParams;
  result: IGetCompetitionDescriptionDetailsResult;
}

const getCompetitionDescriptionDetailsIR: any = {"usedParamSet":{"competitionId":true,"competitionAccessToken":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":217,"b":231}]},{"name":"competitionAccessToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":252,"b":275}]}],"statement":"                                                                                                                      \nSELECT start_date, end_date, display_name, admin_user_id FROM competitions WHERE competition_id = :competitionId! AND access_token = :competitionAccessToken!"};

/**
 * Query generated from SQL:
 * ```
 *                                                                                                                       
 * SELECT start_date, end_date, display_name, admin_user_id FROM competitions WHERE competition_id = :competitionId! AND access_token = :competitionAccessToken!
 * ```
 */
export function getCompetitionDescriptionDetails(params: IGetCompetitionDescriptionDetailsParams): Promise<Array<IGetCompetitionDescriptionDetailsResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getCompetitionDescriptionDetails = new pgtyped.PreparedQuery<IGetCompetitionDescriptionDetailsParams,IGetCompetitionDescriptionDetailsResult>(getCompetitionDescriptionDetailsIR);
    return getCompetitionDescriptionDetails.run(params, DatabaseConnectionPool);
  });
}


/** 'DeleteUserFromCompetition' parameters type */
export interface IDeleteUserFromCompetitionParams {
  competitionId: string;
  userId: Buffer;
}

/** 'DeleteUserFromCompetition' return type */
export type IDeleteUserFromCompetitionResult = void;

/** 'DeleteUserFromCompetition' query type */
export interface IDeleteUserFromCompetitionQuery {
  params: IDeleteUserFromCompetitionParams;
  result: IDeleteUserFromCompetitionResult;
}

const deleteUserFromCompetitionIR: any = {"usedParamSet":{"userId":true,"competitionId":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":47,"b":54}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":77,"b":91}]}],"statement":"DELETE FROM users_competitions WHERE user_id = :userId! AND competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 * DELETE FROM users_competitions WHERE user_id = :userId! AND competition_id = :competitionId!
 * ```
 */
export function deleteUserFromCompetition(params: IDeleteUserFromCompetitionParams): Promise<Array<IDeleteUserFromCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const deleteUserFromCompetition = new pgtyped.PreparedQuery<IDeleteUserFromCompetitionParams,IDeleteUserFromCompetitionResult>(deleteUserFromCompetitionIR);
    return deleteUserFromCompetition.run(params, DatabaseConnectionPool);
  });
}


/** 'UpdateCompetitionAccessToken' parameters type */
export interface IUpdateCompetitionAccessTokenParams {
  competitionId: string;
  newAccessToken: string;
}

/** 'UpdateCompetitionAccessToken' return type */
export type IUpdateCompetitionAccessTokenResult = void;

/** 'UpdateCompetitionAccessToken' query type */
export interface IUpdateCompetitionAccessTokenQuery {
  params: IUpdateCompetitionAccessTokenParams;
  result: IUpdateCompetitionAccessTokenResult;
}

const updateCompetitionAccessTokenIR: any = {"usedParamSet":{"newAccessToken":true,"competitionId":true},"params":[{"name":"newAccessToken","required":true,"transform":{"type":"scalar"},"locs":[{"a":39,"b":54}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":79,"b":93}]}],"statement":"UPDATE competitions SET access_token = :newAccessToken! WHERE competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 * UPDATE competitions SET access_token = :newAccessToken! WHERE competition_id = :competitionId!
 * ```
 */
export function updateCompetitionAccessToken(params: IUpdateCompetitionAccessTokenParams): Promise<Array<IUpdateCompetitionAccessTokenResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const updateCompetitionAccessToken = new pgtyped.PreparedQuery<IUpdateCompetitionAccessTokenParams,IUpdateCompetitionAccessTokenResult>(updateCompetitionAccessTokenIR);
    return updateCompetitionAccessToken.run(params, DatabaseConnectionPool);
  });
}


/** 'GetNumberOfActiveCompetitionsForUser' parameters type */
export interface IGetNumberOfActiveCompetitionsForUserParams {
  currentDate: DateOrString;
  userId: Buffer;
}

/** 'GetNumberOfActiveCompetitionsForUser' return type */
export interface IGetNumberOfActiveCompetitionsForUserResult {
  count: number | null;
}

/** 'GetNumberOfActiveCompetitionsForUser' query type */
export interface IGetNumberOfActiveCompetitionsForUserQuery {
  params: IGetNumberOfActiveCompetitionsForUserParams;
  result: IGetNumberOfActiveCompetitionsForUserResult;
}

const getNumberOfActiveCompetitionsForUserIR: any = {"usedParamSet":{"userId":true,"currentDate":true},"params":[{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":126,"b":133}]},{"name":"currentDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":341,"b":353}]}],"statement":"SELECT COUNT(competitionData.competition_id)::INTEGER FROM\n    (SELECT competition_id FROM users_competitions WHERE user_id = :userId!) as usersCompetitions\n    INNER JOIN\n        (SELECT competition_id, end_date FROM competitions) as competitionData\n    ON usersCompetitions.competition_id = competitionData.competition_id\nWHERE end_date > :currentDate!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT COUNT(competitionData.competition_id)::INTEGER FROM
 *     (SELECT competition_id FROM users_competitions WHERE user_id = :userId!) as usersCompetitions
 *     INNER JOIN
 *         (SELECT competition_id, end_date FROM competitions) as competitionData
 *     ON usersCompetitions.competition_id = competitionData.competition_id
 * WHERE end_date > :currentDate!
 * ```
 */
export function getNumberOfActiveCompetitionsForUser(params: IGetNumberOfActiveCompetitionsForUserParams): Promise<Array<IGetNumberOfActiveCompetitionsForUserResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getNumberOfActiveCompetitionsForUser = new pgtyped.PreparedQuery<IGetNumberOfActiveCompetitionsForUserParams,IGetNumberOfActiveCompetitionsForUserResult>(getNumberOfActiveCompetitionsForUserIR);
    return getNumberOfActiveCompetitionsForUser.run(params, DatabaseConnectionPool);
  });
}


/** 'DeleteCompetition' parameters type */
export interface IDeleteCompetitionParams {
  competitionId: string;
}

/** 'DeleteCompetition' return type */
export type IDeleteCompetitionResult = void;

/** 'DeleteCompetition' query type */
export interface IDeleteCompetitionQuery {
  params: IDeleteCompetitionParams;
  result: IDeleteCompetitionResult;
}

const deleteCompetitionIR: any = {"usedParamSet":{"competitionId":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":48,"b":62}]}],"statement":"DELETE FROM competitions WHERE competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 * DELETE FROM competitions WHERE competition_id = :competitionId!
 * ```
 */
export function deleteCompetition(params: IDeleteCompetitionParams): Promise<Array<IDeleteCompetitionResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const deleteCompetition = new pgtyped.PreparedQuery<IDeleteCompetitionParams,IDeleteCompetitionResult>(deleteCompetitionIR);
    return deleteCompetition.run(params, DatabaseConnectionPool);
  });
}


/** 'GetCompetitionsInState' parameters type */
export interface IGetCompetitionsInStateParams {
  finishedBeforeDate: DateOrString;
  state: number;
}

/** 'GetCompetitionsInState' return type */
export interface IGetCompetitionsInStateResult {
  admin_user_id: Buffer;
  competition_id: string;
  display_name: string;
  end_date: Date;
  iana_timezone: string;
  start_date: Date;
  state: number;
}

/** 'GetCompetitionsInState' query type */
export interface IGetCompetitionsInStateQuery {
  params: IGetCompetitionsInStateParams;
  result: IGetCompetitionsInStateResult;
}

const getCompetitionsInStateIR: any = {"usedParamSet":{"state":true,"finishedBeforeDate":true},"params":[{"name":"state","required":true,"transform":{"type":"scalar"},"locs":[{"a":128,"b":134}]},{"name":"finishedBeforeDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":151,"b":170}]}],"statement":"SELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id, state \nFROM competitions\nWHERE state = :state! AND end_date > :finishedBeforeDate!"};

/**
 * Query generated from SQL:
 * ```
 * SELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id, state 
 * FROM competitions
 * WHERE state = :state! AND end_date > :finishedBeforeDate!
 * ```
 */
export function getCompetitionsInState(params: IGetCompetitionsInStateParams): Promise<Array<IGetCompetitionsInStateResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getCompetitionsInState = new pgtyped.PreparedQuery<IGetCompetitionsInStateParams,IGetCompetitionsInStateResult>(getCompetitionsInStateIR);
    return getCompetitionsInState.run(params, DatabaseConnectionPool);
  });
}


/** 'UpdateCompetitionState' parameters type */
export interface IUpdateCompetitionStateParams {
  competitionId: string;
  newState: number;
}

/** 'UpdateCompetitionState' return type */
export type IUpdateCompetitionStateResult = void;

/** 'UpdateCompetitionState' query type */
export interface IUpdateCompetitionStateQuery {
  params: IUpdateCompetitionStateParams;
  result: IUpdateCompetitionStateResult;
}

const updateCompetitionStateIR: any = {"usedParamSet":{"newState":true,"competitionId":true},"params":[{"name":"newState","required":true,"transform":{"type":"scalar"},"locs":[{"a":32,"b":41}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":66,"b":80}]}],"statement":"UPDATE competitions SET state = :newState! WHERE competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 * UPDATE competitions SET state = :newState! WHERE competition_id = :competitionId!
 * ```
 */
export function updateCompetitionState(params: IUpdateCompetitionStateParams): Promise<Array<IUpdateCompetitionStateResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const updateCompetitionState = new pgtyped.PreparedQuery<IUpdateCompetitionStateParams,IUpdateCompetitionStateResult>(updateCompetitionStateIR);
    return updateCompetitionState.run(params, DatabaseConnectionPool);
  });
}


/** 'UpdateCompetitionFinalPoints' parameters type */
export interface IUpdateCompetitionFinalPointsParams {
  competitionId: string;
  finalPoints: number;
  userId: Buffer;
}

/** 'UpdateCompetitionFinalPoints' return type */
export type IUpdateCompetitionFinalPointsResult = void;

/** 'UpdateCompetitionFinalPoints' query type */
export interface IUpdateCompetitionFinalPointsQuery {
  params: IUpdateCompetitionFinalPointsParams;
  result: IUpdateCompetitionFinalPointsResult;
}

const updateCompetitionFinalPointsIR: any = {"usedParamSet":{"finalPoints":true,"userId":true,"competitionId":true},"params":[{"name":"finalPoints","required":true,"transform":{"type":"scalar"},"locs":[{"a":45,"b":57}]},{"name":"userId","required":true,"transform":{"type":"scalar"},"locs":[{"a":75,"b":82}]},{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":105,"b":119}]}],"statement":"UPDATE users_competitions\nSET final_points = :finalPoints!\nWHERE user_id = :userId! AND competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 * UPDATE users_competitions
 * SET final_points = :finalPoints!
 * WHERE user_id = :userId! AND competition_id = :competitionId!
 * ```
 */
export function updateCompetitionFinalPoints(params: IUpdateCompetitionFinalPointsParams): Promise<Array<IUpdateCompetitionFinalPointsResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const updateCompetitionFinalPoints = new pgtyped.PreparedQuery<IUpdateCompetitionFinalPointsParams,IUpdateCompetitionFinalPointsResult>(updateCompetitionFinalPointsIR);
    return updateCompetitionFinalPoints.run(params, DatabaseConnectionPool);
  });
}


