/* @name ClearAllData */
/* Delete all existing users, which will cascade and delete data from all tables that depend on user (which is everything but oauth_clients) */
DELETE FROM users;

/* @name CreateUser */
INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!);

/* @name CreateRefreshToken */
INSERT INTO oauth_tokens(refresh_token, refresh_token_expires_on, user_id, client_id) VALUES (:refreshToken!, :refreshTokenExpiresOn!, :userId!, :clientId!);

/* @name GetUser */
SELECT * FROM users WHERE user_id = :userId!;

/* @name GetActivitySummariesForUser */
SELECT * FROM activity_summaries WHERE user_id = :userId!;