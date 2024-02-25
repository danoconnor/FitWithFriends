/** Types generated for queries found in "sql/competitions.sql" */
import { PreparedQuery } from '@pgtyped/runtime';

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
export const getUsersCompetitions = new PreparedQuery<IGetUsersCompetitionsParams,IGetUsersCompetitionsResult>(getUsersCompetitionsIR);


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
export const createCompetition = new PreparedQuery<ICreateCompetitionParams,ICreateCompetitionResult>(createCompetitionIR);


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
export const addUserToCompetition = new PreparedQuery<IAddUserToCompetitionParams,IAddUserToCompetitionResult>(addUserToCompetitionIR);


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
}

/** 'GetCompetition' query type */
export interface IGetCompetitionQuery {
  params: IGetCompetitionParams;
  result: IGetCompetitionResult;
}

const getCompetitionIR: any = {"usedParamSet":{"competitionId":true},"params":[{"name":"competitionId","required":true,"transform":{"type":"scalar"},"locs":[{"a":216,"b":230}]}],"statement":"                                                                                      \nSELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id FROM competitions WHERE competition_id = :competitionId!"};

/**
 * Query generated from SQL:
 * ```
 *                                                                                       
 * SELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id FROM competitions WHERE competition_id = :competitionId!
 * ```
 */
export const getCompetition = new PreparedQuery<IGetCompetitionParams,IGetCompetitionResult>(getCompetitionIR);


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
export const getCompetitionAdminDetails = new PreparedQuery<IGetCompetitionAdminDetailsParams,IGetCompetitionAdminDetailsResult>(getCompetitionAdminDetailsIR);


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
export const getNumUsersInCompetition = new PreparedQuery<IGetNumUsersInCompetitionParams,IGetNumUsersInCompetitionResult>(getNumUsersInCompetitionIR);


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
export const getCompetitionDescriptionDetails = new PreparedQuery<IGetCompetitionDescriptionDetailsParams,IGetCompetitionDescriptionDetailsResult>(getCompetitionDescriptionDetailsIR);


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
export const deleteUserFromCompetition = new PreparedQuery<IDeleteUserFromCompetitionParams,IDeleteUserFromCompetitionResult>(deleteUserFromCompetitionIR);


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
export const updateCompetitionAccessToken = new PreparedQuery<IUpdateCompetitionAccessTokenParams,IUpdateCompetitionAccessTokenResult>(updateCompetitionAccessTokenIR);


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
export const getNumberOfActiveCompetitionsForUser = new PreparedQuery<IGetNumberOfActiveCompetitionsForUserParams,IGetNumberOfActiveCompetitionsForUserResult>(getNumberOfActiveCompetitionsForUserIR);


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
export const deleteCompetition = new PreparedQuery<IDeleteCompetitionParams,IDeleteCompetitionResult>(deleteCompetitionIR);

