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
INSERT INTO activity_summaries(user_id, date, calories_burned, calories_goal, exercise_time, exercise_time_goal, stand_time, stand_time_goal, step_count, distance_walking_running_meters, flights_climbed)
VALUES (:userId!, :date!, :caloriesBurned!, :caloriesGoal!, :exerciseTime!, :exerciseTimeGoal!, :standTime!, :standTimeGoal!, COALESCE(:stepCount, 0), COALESCE(:distanceWalkingRunningMeters, 0), COALESCE(:flightsClimbed, 0))
ON CONFLICT (user_id, date) DO UPDATE SET calories_burned = EXCLUDED.calories_burned, calories_goal = EXCLUDED.calories_goal, exercise_time = EXCLUDED.exercise_time, exercise_time_goal = EXCLUDED.exercise_time_goal, stand_time = EXCLUDED.stand_time, stand_time_goal = EXCLUDED.stand_time_goal, step_count = EXCLUDED.step_count, distance_walking_running_meters = EXCLUDED.distance_walking_running_meters, flights_climbed = EXCLUDED.flights_climbed;

/* @name InsertWorkout */
INSERT INTO workouts (user_id, start_date, calories_burned, workout_type, duration, distance, unit)
VALUES (:userId!, :startDate!, :caloriesBurned!, :workoutType!, :duration!, :distance, :unit)
ON CONFLICT (user_id, start_date, workout_type) DO NOTHING;

/* @name CreateCompetition */
INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, scoring_rules)
VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!, :scoringRules);

/* @name CreateCompetitionWithState */
INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, state, scoring_rules)
VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!, :state!, :scoringRules);

/* @name AddUserToCompetition */
INSERT INTO users_competitions (user_id, competition_id)
VALUES (:userId!, :competitionId!);

/* @name UpdateUserCompetitionFinalPoints */
UPDATE users_competitions 
SET final_points = :finalPoints! 
WHERE user_id = :userId! AND competition_id = :competitionId!;

/* @name GetCompetition */
SELECT * FROM competitions WHERE competition_id = :competitionId!;

/* @name GetUsersInCompetition */
SELECT * FROM users_competitions WHERE competition_id = :competitionId!;

/* @name GetPushTokenForUser */
SELECT * FROM push_tokens WHERE user_id = :userId!;

/* @name GetWorkoutsForUser */
SELECT * FROM workouts WHERE user_id = :userId!;

/* @name GetRefreshTokens */
SELECT * FROM oauth_tokens;

/* @name DeleteAllRefreshTokens */
DELETE FROM oauth_tokens;

/* @name CreatePushToken */
INSERT INTO push_tokens (user_id, push_token, platform, app_install_id)
VALUES (:userId!, :pushToken!, :platform!, :appInstallId!)
ON CONFLICT (user_id, platform, app_install_id) DO UPDATE SET push_token = EXCLUDED.push_token;

/* @name CreatePublicCompetition */
INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, is_public)
VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!, true);

/* @name UpdateUserProStatus */
UPDATE users SET is_pro = :isPro!, max_active_competitions = :maxActiveCompetitions!
WHERE user_id = :userId!;

/* @name UpdateCompetitionState */
UPDATE competitions SET state = :state! WHERE competition_id = :competitionId!;

/* @name CreateBotUser */
INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date, is_bot)
VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!, true);

/* @name GetBotUsers */
SELECT encode(user_id::bytea, 'hex') AS "userId!" FROM users WHERE is_bot = true;