/** Types generated for queries found in "sql/activitySummaries.sql" */
import { DatabaseConnectionPool } from '../utilities/database';

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
export function getActivitySummariesForUsers(params: IGetActivitySummariesForUsersParams): Promise<Array<IGetActivitySummariesForUsersResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getActivitySummariesForUsers = new pgtyped.PreparedQuery<IGetActivitySummariesForUsersParams,IGetActivitySummariesForUsersResult>(getActivitySummariesForUsersIR);
    return getActivitySummariesForUsers.run(params, DatabaseConnectionPool);
  });
}


/** 'InsertActivitySummaries' parameters type */
export interface IInsertActivitySummariesParams {
  summaries: readonly ({
    user_id: Buffer,
    date: DateOrString,
    calories_burned: number,
    calories_goal: number,
    exercise_time: number,
    exercise_time_goal: number,
    stand_time: number,
    stand_time_goal: number
  })[];
}

/** 'InsertActivitySummaries' return type */
export type IInsertActivitySummariesResult = void;

/** 'InsertActivitySummaries' query type */
export interface IInsertActivitySummariesQuery {
  params: IInsertActivitySummariesParams;
  result: IInsertActivitySummariesResult;
}

const insertActivitySummariesIR: any = {"usedParamSet":{"summaries":true},"params":[{"name":"summaries","required":true,"transform":{"type":"pick_array_spread","keys":[{"name":"user_id","required":true},{"name":"date","required":true},{"name":"calories_burned","required":true},{"name":"calories_goal","required":true},{"name":"exercise_time","required":true},{"name":"exercise_time_goal","required":true},{"name":"stand_time","required":true},{"name":"stand_time_goal","required":true}]},"locs":[{"a":149,"b":159}]}],"statement":"INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal)\nVALUES :summaries!\nON CONFLICT (user_id, date) DO UPDATE SET \n    calories_burned = GREATEST(activity_summaries.calories_burned, EXCLUDED.calories_burned), \n    calories_goal = GREATEST(activity_summaries.calories_goal, EXCLUDED.calories_goal), \n    exercise_time = GREATEST(activity_summaries.exercise_time, EXCLUDED.exercise_time),\n    exercise_time_goal = GREATEST(activity_summaries.exercise_time_goal, EXCLUDED.exercise_time_goal), \n    stand_time = GREATEST(activity_summaries.stand_time, EXCLUDED.stand_time), \n    stand_time_goal = GREATEST(activity_summaries.stand_time_goal, EXCLUDED.stand_time_goal)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal)
 * VALUES :summaries!
 * ON CONFLICT (user_id, date) DO UPDATE SET 
 *     calories_burned = GREATEST(activity_summaries.calories_burned, EXCLUDED.calories_burned), 
 *     calories_goal = GREATEST(activity_summaries.calories_goal, EXCLUDED.calories_goal), 
 *     exercise_time = GREATEST(activity_summaries.exercise_time, EXCLUDED.exercise_time),
 *     exercise_time_goal = GREATEST(activity_summaries.exercise_time_goal, EXCLUDED.exercise_time_goal), 
 *     stand_time = GREATEST(activity_summaries.stand_time, EXCLUDED.stand_time), 
 *     stand_time_goal = GREATEST(activity_summaries.stand_time_goal, EXCLUDED.stand_time_goal)
 * ```
 */
export function insertActivitySummaries(params: IInsertActivitySummariesParams): Promise<Array<IInsertActivitySummariesResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const insertActivitySummaries = new pgtyped.PreparedQuery<IInsertActivitySummariesParams,IInsertActivitySummariesResult>(insertActivitySummariesIR);
    return insertActivitySummaries.run(params, DatabaseConnectionPool);
  });
}


