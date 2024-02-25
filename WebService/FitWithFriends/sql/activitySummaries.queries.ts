/** Types generated for queries found in "sql/activitySummaries.sql" */
import { PreparedQuery } from '@pgtyped/runtime';

export type DateOrString = Date | string;

/** 'GetActivitySummariesForUsers' parameters type */
export interface IGetActivitySummariesForUsersParams {
  endDate: DateOrString;
  startDate: DateOrString;
  userIds: readonly (Buffer)[];
}

/** 'GetActivitySummariesForUsers' return type */
export interface IGetActivitySummariesForUsersResult {
  calories_burned: number;
  calories_goal: number;
  date: Date;
  exercise_time: number;
  exercise_time_goal: number;
  stand_time: number;
  stand_time_goal: number;
  userId: string;
}

/** 'GetActivitySummariesForUsers' query type */
export interface IGetActivitySummariesForUsersQuery {
  params: IGetActivitySummariesForUsersParams;
  result: IGetActivitySummariesForUsersResult;
}

const getActivitySummariesForUsersIR: any = {"usedParamSet":{"userIds":true,"endDate":true,"startDate":true},"params":[{"name":"userIds","required":true,"transform":{"type":"array_spread"},"locs":[{"a":279,"b":287}]},{"name":"endDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":301,"b":309}]},{"name":"startDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":323,"b":333}]}],"statement":"                                                                                    \nSELECT encode(user_id::bytea, 'hex') AS \"userId!\", date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal \nFROM activity_summaries\nWHERE user_id in :userIds! AND date <= :endDate! AND date >= :startDate!"};

/**
 * Query generated from SQL:
 * ```
 *                                                                                     
 * SELECT encode(user_id::bytea, 'hex') AS "userId!", date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal 
 * FROM activity_summaries
 * WHERE user_id in :userIds! AND date <= :endDate! AND date >= :startDate!
 * ```
 */
export const getActivitySummariesForUsers = new PreparedQuery<IGetActivitySummariesForUsersParams,IGetActivitySummariesForUsersResult>(getActivitySummariesForUsersIR);


