/* @name RegisterPushToken */
INSERT INTO push_tokens(user_id, push_token, platform) 
VALUES (:userId!, :pushToken!, :platform!)
ON CONFLICT (user_id, push_token, platform) DO NOTHING;