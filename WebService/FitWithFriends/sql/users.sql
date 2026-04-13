/* @name CreateUser */
INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date) VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!);

/* @name GetUserName */
SELECT first_name, last_name FROM users WHERE user_id = :userId!;

/* @name GetUserMaxCompetitions */
SELECT max_active_competitions FROM users WHERE user_id = :userId!;

/* @name GetUsersInCompetition */
SELECT encode(userData.user_id::bytea, 'hex') AS "userId!", userData.first_name, userData.last_name, usersCompetitions.final_points AS "finalPoints!" FROM
    (SELECT user_id, final_points FROM users_competitions WHERE competition_id = :competitionId!) AS usersCompetitions
    INNER JOIN (SELECT user_id, first_name, last_name FROM users) as userData
    ON usersCompetitions.user_id = userData.user_id;

/* @name GetUserProStatus */
SELECT is_pro FROM users WHERE user_id = :userId!;

/* @name UpdateUserProStatus */
UPDATE users SET is_pro = :isPro!, max_active_competitions = :maxActiveCompetitions!
WHERE user_id = :userId!;

/* @name UpdateUserSubscriptionInfo */
UPDATE users
SET is_pro = :isPro!, max_active_competitions = :maxActiveCompetitions!,
    apple_original_transaction_id = :originalTransactionId, subscription_expires_date = :expiresDate
WHERE user_id = :userId!;

/* @name GetUserByOriginalTransactionId */
SELECT user_id FROM users WHERE apple_original_transaction_id = :originalTransactionId!;

/* @name CreateBotUser */
INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date, is_bot)
VALUES (:userId!, :firstName!, :lastName, :maxActiveCompetitions!, :isPro!, :createdDate!, true);

/* @name GetBotUsers */
SELECT encode(user_id::bytea, 'hex') AS "userId!" FROM users WHERE is_bot = true;

/* @name GetBotUserCount */
SELECT COUNT(*)::INTEGER AS "count!" FROM users WHERE is_bot = true;