/* 
    @name GetActivitySummariesForUsers
    @param userIds -> (...) 
*/
/* Returns all the activity summaries for the given users in the given date range */
SELECT encode(user_id::bytea, 'hex') AS "userId!", date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal 
FROM activity_summaries
WHERE user_id in :userIds! AND date <= :endDate! AND date >= :startDate!;

/* 
    @name InsertActivitySummaries 
    @param summaries -> ((user_id!, date!, calories_burned!, calories_goal!, exercise_time!, exercise_time_goal!, stand_time!, stand_time_goal!)...)
*/
INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal)
VALUES :summaries!
ON CONFLICT (user_id, date) DO UPDATE SET 
    calories_burned = GREATEST(activity_summaries.calories_burned, EXCLUDED.calories_burned), 
    calories_goal = GREATEST(activity_summaries.calories_goal, EXCLUDED.calories_goal), 
    exercise_time = GREATEST(activity_summaries.exercise_time, EXCLUDED.exercise_time),
    exercise_time_goal = GREATEST(activity_summaries.exercise_time_goal, EXCLUDED.exercise_time_goal), 
    stand_time = GREATEST(activity_summaries.stand_time, EXCLUDED.stand_time), 
    stand_time_goal = GREATEST(activity_summaries.stand_time_goal, EXCLUDED.stand_time_goal);