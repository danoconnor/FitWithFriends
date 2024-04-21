-- Add a default OAuth client ID and secret so our tests can communicate with the server (these values will be hardcoded into the tests)
INSERT INTO oauth_clients (client_id, client_secret, redirect_uri) 
VALUES ('6A773C32-5EB3-41C9-8036-B991B51F14F7', '11279ED4-2687-408D-9AE7-22AB3CA41219', 'SOMEURI');

-- Add a default user so we can login when running the app locally. The app will override any actual credentials to use this hardcoded userId
INSERT INTO users(user_id, first_name, last_name, max_active_competitions, is_pro, created_date)
VALUES ('\xabcdef1234567890', 'Test', 'User', 10, true, '2024-01-01 00:00:00.000');