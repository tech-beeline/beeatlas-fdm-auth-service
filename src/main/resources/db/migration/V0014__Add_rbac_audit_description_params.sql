ALTER TABLE user_auth.rbac_audit_log
    ADD COLUMN effect      VARCHAR(10),
    ADD COLUMN description TEXT,
    ADD COLUMN params      TEXT;

UPDATE user_auth.rbac_audit_log SET effect = 'DENY' WHERE effect IS NULL;

ALTER TABLE user_auth.rbac_audit_log ALTER COLUMN effect SET NOT NULL;
