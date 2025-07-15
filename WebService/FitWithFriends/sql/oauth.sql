/* @name GetClient */
SELECT client_id, client_secret, redirect_uri FROM oauth_clients WHERE client_id = :clientId! AND client_secret = :clientSecret!;

/* @name GetRefreshToken */
SELECT client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE refresh_token = :refreshToken!;

/* @name SaveRefreshToken */
INSERT INTO oauth_tokens(client_id, refresh_token, refresh_token_expires_on, user_id) VALUES (:clientId!, :refreshToken!, :refreshTokenExpiresOn!, :userId!);

/* @name DeleteRefreshToken */
DELETE FROM oauth_tokens WHERE refresh_token = :refreshToken!;

/* @name DeleteExpiredRefreshTokens */
DELETE FROM oauth_tokens WHERE refresh_token_expires_on < :currentDate!;