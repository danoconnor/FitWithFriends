/* 
    @name GetActivitySummariesForUsers
    @param userIds -> (...) 
*/
/* Returns all the activity summaries for the given users in the given date range */
SELECT encode(user_id::bytea, 'hex') AS "userId!", date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal 
FROM activity_summaries
WHERE user_id in :userIds! AND date <= :endDate! AND date >= :startDate!;