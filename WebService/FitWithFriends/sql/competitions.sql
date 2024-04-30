/* @name GetUsersCompetitions */
SELECT competition_id from users_competitions WHERE user_id = :userId!;

/* @name CreateCompetition */
INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id) VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!);

/* @name AddUserToCompetition */
INSERT INTO users_competitions (user_id, competition_id) 
VALUES (:userId!, :competitionId!)
ON CONFLICT (user_id, competition_id) DO NOTHING;

/* @name GetCompetition */
/* Does not return the access_token field - we will only return that to admin users */
SELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id, state FROM competitions WHERE competition_id = :competitionId!;

/* @name GetCompetitionAdminDetails */
SELECT start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id FROM competitions WHERE competition_id = :competitionId! AND admin_user_id = :adminUserId!;

/* @name GetNumUsersInCompetition */
SELECT count(user_id)::INTEGER FROM users_competitions WHERE competition_id = :competitionId!;

/* @name GetCompetitionDescriptionDetails */
/* Returns some details about the competition, authenticated by the client providing the competition's access token */
SELECT start_date, end_date, display_name, admin_user_id FROM competitions WHERE competition_id = :competitionId! AND access_token = :competitionAccessToken!;

/* @name DeleteUserFromCompetition */
DELETE FROM users_competitions WHERE user_id = :userId! AND competition_id = :competitionId!;

/* @name UpdateCompetitionAccessToken */
UPDATE competitions SET access_token = :newAccessToken! WHERE competition_id = :competitionId!;

/* @name GetNumberOfActiveCompetitionsForUser */
SELECT COUNT(competitionData.competition_id)::INTEGER FROM
    (SELECT competition_id FROM users_competitions WHERE user_id = :userId!) as usersCompetitions
    INNER JOIN
        (SELECT competition_id, end_date FROM competitions) as competitionData
    ON usersCompetitions.competition_id = competitionData.competition_id
WHERE end_date > :currentDate!;

/* @name DeleteCompetition */
DELETE FROM competitions WHERE competition_id = :competitionId!;

/* @name GetCompetitionsInState */
SELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id, state 
FROM competitions
WHERE state = :state! AND end_date > :finishedBeforeDate!;