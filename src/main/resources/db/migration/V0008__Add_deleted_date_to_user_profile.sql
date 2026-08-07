ALTER TABLE user_auth.user_profile
    ADD COLUMN deleted_date timestamp NULL;

COMMENT ON COLUMN user_auth.user_profile.deleted_date IS 'Дата увольнения сотрудника';

