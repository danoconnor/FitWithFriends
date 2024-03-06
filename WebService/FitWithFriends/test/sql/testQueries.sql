/* @name ClearAllData */
/* Delete all existing users, which will cascade and delete data from all tables that depend on user (which is everything but oauth_clients) */
DELETE FROM users;

/* @name CreateUser */
INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!);