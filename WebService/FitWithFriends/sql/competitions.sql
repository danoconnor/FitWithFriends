/* @name GetUsersCompetitions */
SELECT competition_id from users_competitions WHERE user_id = :userId!;

/* @name GetUsersForCompetition */
SELECT user_id, final_points FROM users_competitions WHERE competition_id = :competitionId!;

/* @name CreateCompetition */
INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, scoring_rules)
VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!, :scoringRules);

/* @name AddUserToCompetition */
INSERT INTO users_competitions (user_id, competition_id) 
VALUES (:userId!, :competitionId!)
ON CONFLICT (user_id, competition_id) DO NOTHING;

/* @name GetCompetition */
/* Does not return the access_token field - we will only return that to admin users */
SELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id, state, is_public, scoring_rules FROM competitions WHERE competition_id = :competitionId!;

/* @name GetCompetitionAdminDetails */
SELECT start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, scoring_rules FROM competitions WHERE competition_id = :competitionId! AND admin_user_id = :adminUserId!;

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
/* Only counts private competitions - public competitions do not count toward the user's limit */
SELECT COUNT(competitionData.competition_id)::INTEGER FROM
    (SELECT competition_id FROM users_competitions WHERE user_id = :userId!) as usersCompetitions
    INNER JOIN
        (SELECT competition_id, end_date FROM competitions WHERE is_public = false) as competitionData
    ON usersCompetitions.competition_id = competitionData.competition_id
WHERE end_date > :currentDate!;

/* @name DeleteCompetition */
DELETE FROM competitions WHERE competition_id = :competitionId!;

/* @name GetCompetitionsInState */
SELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id, state, is_public, scoring_rules
FROM competitions
WHERE state = :state! AND end_date < :finishedBeforeDate!;

/* @name UpdateCompetitionState */
UPDATE competitions SET state = :newState! WHERE competition_id = :competitionId!;

/* @name UpdateCompetitionDates */
UPDATE competitions SET start_date = :startDate!, end_date = :endDate! WHERE competition_id = :competitionId!;

/* @name UpdateCompetitionFinalPoints */
UPDATE users_competitions
SET final_points = :finalPoints!
WHERE user_id = :userId! AND competition_id = :competitionId!;

/* @name GetPublicCompetitions */
SELECT c.competition_id, c.display_name, c.start_date, c.end_date, c.iana_timezone, c.state,
       COUNT(uc.user_id)::INTEGER AS "member_count!"
FROM competitions c
LEFT JOIN users_competitions uc ON c.competition_id = uc.competition_id
WHERE c.is_public = true AND c.state = :activeState!
GROUP BY c.competition_id;

/* @name CreatePublicCompetition */
INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id, is_public, scoring_rules)
VALUES (:startDate!, :endDate!, :displayName!, :adminUserId!, :accessToken!, :ianaTimezone!, :competitionId!, true, :scoringRules);

/* @name GetPublicCompetition */
SELECT start_date, end_date, display_name, admin_user_id, iana_timezone, competition_id, state, is_public, scoring_rules
FROM competitions
WHERE competition_id = :competitionId! AND is_public = true;

/* @name IsUserInCompetition */
SELECT COUNT(*)::INTEGER AS "count!" FROM users_competitions
WHERE user_id = :userId! AND competition_id = :competitionId!;

/* @name GetCompetitionInviteDetails */
/* Used by the web /joinCompetition route. Returns enough metadata to render an
   inviter-aware hero card without requiring the visitor to authenticate. The
   visitor proves they hold a valid access token by passing it in :accessToken. */
SELECT
    c.competition_id,
    c.display_name,
    c.start_date,
    c.end_date,
    c.is_public,
    c.scoring_rules,
    admin_user.first_name AS "admin_first_name!",
    admin_user.last_name AS "admin_last_name",
    (
        SELECT COUNT(*)::INTEGER FROM users_competitions uc_count
        WHERE uc_count.competition_id = c.competition_id
    ) AS "member_count!",
    (
        SELECT COALESCE(
            json_agg(
                json_build_object(
                    'firstName', mu.first_name,
                    'lastName', mu.last_name
                ) ORDER BY mu.first_name
            ),
            '[]'::json
        )
        FROM users_competitions uc
        JOIN users mu ON mu.user_id = uc.user_id
        WHERE uc.competition_id = c.competition_id
    ) AS "members!"
FROM competitions c
JOIN users admin_user ON admin_user.user_id = c.admin_user_id
WHERE c.competition_id = :competitionId!
  AND c.access_token = :competitionAccessToken!;