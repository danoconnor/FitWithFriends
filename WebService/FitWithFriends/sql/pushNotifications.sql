/* @name RegisterPushToken */
INSERT INTO push_tokens(user_id, push_token, platform, app_install_id) 
VALUES (:userId!, :pushToken!, :platform!, :appInstallId!)
ON CONFLICT (user_id, platform, app_install_id) DO UPDATE SET push_token = EXCLUDED.push_token;