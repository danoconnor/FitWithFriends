/*
    @name GetActivitySummariesForUsers
    @param userIds -> (...)
*/
/* Returns all the activity summaries for the given users in the given date range */
SELECT encode(user_id::bytea, 'hex') AS "userId!", date,
       calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal,
       step_count, distance_walking_running_meters, flights_climbed
FROM activity_summaries
WHERE user_id in :userIds! AND date <= :endDate! AND date >= :startDate!;

/*
    @name InsertActivitySummaries
    @param summaries -> ((userId!, date!, caloriesBurned!, caloriesGoal!, exerciseTime!, exerciseTimeGoal!, standTime!, standTimeGoal!, stepCount!, distanceWalkingRunningMeters!, flightsClimbed!)...)
*/
INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal, step_count, distance_walking_running_meters, flights_climbed)
VALUES :summaries!
ON CONFLICT (user_id, date) DO UPDATE SET
    calories_burned = GREATEST(activity_summaries.calories_burned, EXCLUDED.calories_burned),
    calories_goal = GREATEST(activity_summaries.calories_goal, EXCLUDED.calories_goal),
    exercise_time = GREATEST(activity_summaries.exercise_time, EXCLUDED.exercise_time),
    exercise_time_goal = GREATEST(activity_summaries.exercise_time_goal, EXCLUDED.exercise_time_goal),
    stand_time = GREATEST(activity_summaries.stand_time, EXCLUDED.stand_time),
    stand_time_goal = GREATEST(activity_summaries.stand_time_goal, EXCLUDED.stand_time_goal),
    step_count = GREATEST(activity_summaries.step_count, EXCLUDED.step_count),
    distance_walking_running_meters = GREATEST(activity_summaries.distance_walking_running_meters, EXCLUDED.distance_walking_running_meters),
    flights_climbed = GREATEST(activity_summaries.flights_climbed, EXCLUDED.flights_climbed);

/*
    @name InsertWorkouts
    @param workouts -> ((userId!, startDate!, caloriesBurned!, workoutType!, duration!, distance, unit)...)
*/
INSERT INTO workouts(user_id, start_date, calories_burned, workout_type, duration, distance, unit)
VALUES :workouts!
ON CONFLICT (user_id, start_date, workout_type) DO NOTHING;

/*
    @name GetWorkoutsForUsersInDateRange
    @param userIds -> (...)
*/
/* Returns all workouts for the given users in the given date range. Used by workout-based scoring rules. */
SELECT encode(user_id::bytea, 'hex') AS "userId!", start_date, workout_type, duration, distance, unit, calories_burned
FROM workouts
WHERE user_id in :userIds! AND start_date <= :endDate! AND start_date >= :startDate!;
