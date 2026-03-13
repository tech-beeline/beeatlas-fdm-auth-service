DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM user_auth.user_profile LIMIT 1) THEN
        INSERT INTO user_auth.user_profile (id, id_ext, full_name, login, email)
        VALUES (0, 1, 'Ivan Ivanov', 'defaultUser', 'default@beeline.ru');

INSERT INTO user_auth.user_roles (id_rec, id_profile, id_role)
VALUES (0, 0, 2);
END IF;
END $$;
