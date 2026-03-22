SELECT user_id,
	   username,
	   password AS hashed_password,
	   NOT is_active AS disabled
FROM users
WHERE username = :username;