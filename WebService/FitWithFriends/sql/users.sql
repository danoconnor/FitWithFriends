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