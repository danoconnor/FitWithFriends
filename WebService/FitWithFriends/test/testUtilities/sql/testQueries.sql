/* @name ClearAllData */
/* Delete all existing users, which will cascade and delete data from all tables that depend on user (which is everything but oauth_clients) */
DELETE FROM users;

/* @name ClearDataForUser */
/* Delete all data for a specific user, which will cascade and delete data from all tables that depend on user (which is everything but oauth_clients) */
DELETE FROM users WHERE user_id = :userId!;

/* @name ClearDataForCompetition */
/* Delete all data for a specific competition, which will cascade and delete data from all tables that depend on competition */
DELETE FROM competitions WHERE competition_id = :competitionId!;

/* @name CreateUser */
INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!);

/* @name CreateRefreshToken */
INSERT INTO oauth_tokens(refresh_token, refresh_token_expires_on, user_id, client_id) VALUES (:refreshToken!, :refreshTokenExpiresOn!, :userId!, :clientId!);

/* @name GetUser */
SELECT * FROM users WHERE user_id = :userId!;

/* @name GetActivitySummariesForUser */
SELECT * FROM activity_summaries WHERE user_id = :userId!;

/* @name InsertActivitySummary */
INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal)
VALUES (:userId!, :date!, :caloriesBurned!, :caloriesGoal!, :exerciseTime!, :exerciseTimeGoal!, :standTime!, :standTimeGoal!)
ON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal;

/* @name CreateCompetition */
INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id) 
VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!);

/* @name AddUserToCompetition */
INSERT INTO users_competitions (user_id, competition_id)
VALUES (:userId!, :competitionId!);

/* @name GetCompetition */
SELECT * FROM competitions WHERE competition_id = :competitionId!;

/* @name GetUsersInCompetition */
SELECT * FROM users_competitions WHERE competition_id = :competitionId!;

/* @name GetPushTokenForUser */
SELECT * FROM push_tokens WHERE user_id = :userId!;