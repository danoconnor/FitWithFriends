/** Types generated for queries found in "sql/activityData.sql" */
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
  distance_walking_running_meters: number;
  exercise_time: number;
  exercise_time_goal: number;
  flights_climbed: number;
  stand_time: number;
  stand_time_goal: number;
  step_count: number;
  userId: string;
}

/** 'GetActivitySummariesForUsers' query type */
export interface IGetActivitySummariesForUsersQuery {
  params: IGetActivitySummariesForUsersParams;
  result: IGetActivitySummariesForUsersResult;
}

const getActivitySummariesForUsersIR: any = {"usedParamSet":{"userIds":true,"endDate":true,"startDate":true},"params":[{"name":"userIds","required":true,"transform":{"type":"array_spread"},"locs":[{"a":354,"b":362}]},{"name":"endDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":376,"b":384}]},{"name":"startDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":398,"b":408}]}],"statement":"                                                                                    \nSELECT encode(user_id::bytea, 'hex') AS \"userId!\", date,\n       calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal,\n       step_count, distance_walking_running_meters, flights_climbed\nFROM activity_summaries\nWHERE user_id in :userIds! AND date <= :endDate! AND date >= :startDate!"};

/**
 * Query generated from SQL:
 * ```
 *                                                                                     
 * SELECT encode(user_id::bytea, 'hex') AS "userId!", date,
 *        calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal,
 *        step_count, distance_walking_running_meters, flights_climbed
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
    userId: Buffer,
    date: DateOrString,
    caloriesBurned: number,
    caloriesGoal: number,
    exerciseTime: number,
    exerciseTimeGoal: number,
    standTime: number,
    standTimeGoal: number,
    stepCount: number,
    distanceWalkingRunningMeters: number,
    flightsClimbed: number
  })[];
}

/** 'InsertActivitySummaries' return type */
export type IInsertActivitySummariesResult = void;

/** 'InsertActivitySummaries' query type */
export interface IInsertActivitySummariesQuery {
  params: IInsertActivitySummariesParams;
  result: IInsertActivitySummariesResult;
}

const insertActivitySummariesIR: any = {"usedParamSet":{"summaries":true},"params":[{"name":"summaries","required":true,"transform":{"type":"pick_array_spread","keys":[{"name":"userId","required":true},{"name":"date","required":true},{"name":"caloriesBurned","required":true},{"name":"caloriesGoal","required":true},{"name":"exerciseTime","required":true},{"name":"exerciseTimeGoal","required":true},{"name":"standTime","required":true},{"name":"standTimeGoal","required":true},{"name":"stepCount","required":true},{"name":"distanceWalkingRunningMeters","required":true},{"name":"flightsClimbed","required":true}]},"locs":[{"a":211,"b":221}]}],"statement":"INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal, step_count, distance_walking_running_meters, flights_climbed)\nVALUES :summaries!\nON CONFLICT (user_id, date) DO UPDATE SET\n    calories_burned = GREATEST(activity_summaries.calories_burned, EXCLUDED.calories_burned),\n    calories_goal = GREATEST(activity_summaries.calories_goal, EXCLUDED.calories_goal),\n    exercise_time = GREATEST(activity_summaries.exercise_time, EXCLUDED.exercise_time),\n    exercise_time_goal = GREATEST(activity_summaries.exercise_time_goal, EXCLUDED.exercise_time_goal),\n    stand_time = GREATEST(activity_summaries.stand_time, EXCLUDED.stand_time),\n    stand_time_goal = GREATEST(activity_summaries.stand_time_goal, EXCLUDED.stand_time_goal),\n    step_count = GREATEST(activity_summaries.step_count, EXCLUDED.step_count),\n    distance_walking_running_meters = GREATEST(activity_summaries.distance_walking_running_meters, EXCLUDED.distance_walking_running_meters),\n    flights_climbed = GREATEST(activity_summaries.flights_climbed, EXCLUDED.flights_climbed)"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal, step_count, distance_walking_running_meters, flights_climbed)
 * VALUES :summaries!
 * ON CONFLICT (user_id, date) DO UPDATE SET
 *     calories_burned = GREATEST(activity_summaries.calories_burned, EXCLUDED.calories_burned),
 *     calories_goal = GREATEST(activity_summaries.calories_goal, EXCLUDED.calories_goal),
 *     exercise_time = GREATEST(activity_summaries.exercise_time, EXCLUDED.exercise_time),
 *     exercise_time_goal = GREATEST(activity_summaries.exercise_time_goal, EXCLUDED.exercise_time_goal),
 *     stand_time = GREATEST(activity_summaries.stand_time, EXCLUDED.stand_time),
 *     stand_time_goal = GREATEST(activity_summaries.stand_time_goal, EXCLUDED.stand_time_goal),
 *     step_count = GREATEST(activity_summaries.step_count, EXCLUDED.step_count),
 *     distance_walking_running_meters = GREATEST(activity_summaries.distance_walking_running_meters, EXCLUDED.distance_walking_running_meters),
 *     flights_climbed = GREATEST(activity_summaries.flights_climbed, EXCLUDED.flights_climbed)
 * ```
 */
export function insertActivitySummaries(params: IInsertActivitySummariesParams): Promise<Array<IInsertActivitySummariesResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const insertActivitySummaries = new pgtyped.PreparedQuery<IInsertActivitySummariesParams,IInsertActivitySummariesResult>(insertActivitySummariesIR);
    return insertActivitySummaries.run(params, DatabaseConnectionPool);
  });
}


/** 'InsertWorkouts' parameters type */
export interface IInsertWorkoutsParams {
  workouts: readonly ({
    userId: Buffer,
    startDate: DateOrString,
    caloriesBurned: number,
    workoutType: number,
    duration: number,
    distance: number | null | void,
    unit: number | null | void
  })[];
}

/** 'InsertWorkouts' return type */
export type IInsertWorkoutsResult = void;

/** 'InsertWorkouts' query type */
export interface IInsertWorkoutsQuery {
  params: IInsertWorkoutsParams;
  result: IInsertWorkoutsResult;
}

const insertWorkoutsIR: any = {"usedParamSet":{"workouts":true},"params":[{"name":"workouts","required":true,"transform":{"type":"pick_array_spread","keys":[{"name":"userId","required":true},{"name":"startDate","required":true},{"name":"caloriesBurned","required":true},{"name":"workoutType","required":true},{"name":"duration","required":true},{"name":"distance","required":false},{"name":"unit","required":false}]},"locs":[{"a":106,"b":115}]}],"statement":"INSERT INTO workouts(user_id, start_date, calories_burned, workout_type, duration, distance, unit)\nVALUES :workouts!\nON CONFLICT (user_id, start_date, workout_type) DO NOTHING"};

/**
 * Query generated from SQL:
 * ```
 * INSERT INTO workouts(user_id, start_date, calories_burned, workout_type, duration, distance, unit)
 * VALUES :workouts!
 * ON CONFLICT (user_id, start_date, workout_type) DO NOTHING
 * ```
 */
export function insertWorkouts(params: IInsertWorkoutsParams): Promise<Array<IInsertWorkoutsResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const insertWorkouts = new pgtyped.PreparedQuery<IInsertWorkoutsParams,IInsertWorkoutsResult>(insertWorkoutsIR);
    return insertWorkouts.run(params, DatabaseConnectionPool);
  });
}


/** 'GetWorkoutsForUsersInDateRange' parameters type */
export interface IGetWorkoutsForUsersInDateRangeParams {
  endDate: DateOrString;
  startDate: DateOrString;
  userIds: readonly (Buffer)[];
}

/** 'GetWorkoutsForUsersInDateRange' return type */
export interface IGetWorkoutsForUsersInDateRangeResult {
  calories_burned: number;
  distance: number | null;
  duration: number;
  start_date: Date;
  unit: number | null;
  userId: string;
  workout_type: number;
}

/** 'GetWorkoutsForUsersInDateRange' query type */
export interface IGetWorkoutsForUsersInDateRangeQuery {
  params: IGetWorkoutsForUsersInDateRangeParams;
  result: IGetWorkoutsForUsersInDateRangeResult;
}

const getWorkoutsForUsersInDateRangeIR: any = {"usedParamSet":{"userIds":true,"endDate":true,"startDate":true},"params":[{"name":"userIds","required":true,"transform":{"type":"array_spread"},"locs":[{"a":259,"b":267}]},{"name":"endDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":287,"b":295}]},{"name":"startDate","required":true,"transform":{"type":"scalar"},"locs":[{"a":315,"b":325}]}],"statement":"                                                                                                            \nSELECT encode(user_id::bytea, 'hex') AS \"userId!\", start_date, workout_type, duration, distance, unit, calories_burned\nFROM workouts\nWHERE user_id in :userIds! AND start_date <= :endDate! AND start_date >= :startDate!"};

/**
 * Query generated from SQL:
 * ```
 *                                                                                                             
 * SELECT encode(user_id::bytea, 'hex') AS "userId!", start_date, workout_type, duration, distance, unit, calories_burned
 * FROM workouts
 * WHERE user_id in :userIds! AND start_date <= :endDate! AND start_date >= :startDate!
 * ```
 */
export function getWorkoutsForUsersInDateRange(params: IGetWorkoutsForUsersInDateRangeParams): Promise<Array<IGetWorkoutsForUsersInDateRangeResult>> {
  return import('@pgtyped/runtime').then(pgtyped => {
    const getWorkoutsForUsersInDateRange = new pgtyped.PreparedQuery<IGetWorkoutsForUsersInDateRangeParams,IGetWorkoutsForUsersInDateRangeResult>(getWorkoutsForUsersInDateRangeIR);
    return getWorkoutsForUsersInDateRange.run(params, DatabaseConnectionPool);
  });
}


