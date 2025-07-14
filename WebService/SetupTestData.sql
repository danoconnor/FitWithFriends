-- Add a default OAuth client ID and secret so our tests can communicate with the server (these values will be hardcoded into the tests)
INSERT INTO oauth_clients (client_id, client_secret, redirect_uri) 
VALUES ('6A773C32-5EB3-41C9-8036-B991B51F14F7', '11279ED4-2687-408D-9AE7-22AB3CA41219', 'SOMEURI');

-- Add a default user so we can login when running the app locally. The app will override any actual credentials to use this hardcoded userId
INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date)
VALUES ('\xabcdef1234567890', 'Test', 'User', 10, true, '2024-01-01 00:00:00.000');

-- Add a competition for the test user
INSERT INTO competitions (start_date, end_date, display_name, admin_user_id, access_token, iana_timezone, competition_id) 
VALUES ('2024-01-01 00:00:00.000', '2024-01-31 23:59:59.999', 'Test Competition', '\xabcdef1234567890', 'TEST_ACCESS_TOKEN', 'America/New_York', '12345678-1234-1234-1234-123456789012');

-- Add the test user to the competition
INSERT INTO users_competitions (user_id, competition_id) 
VALUES ('\xabcdef1234567890', '12345678-1234-1234-1234-123456789012')
ON CONFLICT (user_id, competition_id) DO NOTHING;

-- Add a push token for the test user
INSERT INTO push_tokens (user_id, push_token, platform, app_install_id) 
VALUES ('\xabcdef1234567890', 'TEST_PUSH_TOKEN', 1, '12345678-1234-1234-1234-123456789012')
ON CONFLICT (user_id, platform, app_install_id) DO UPDATE SET push_token = EXCLUDED.push_token;