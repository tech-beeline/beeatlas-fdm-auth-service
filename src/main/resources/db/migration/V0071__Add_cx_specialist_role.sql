SELECT setval(
    'user_auth.role_id_seq',
    GREATEST((SELECT COALESCE(MAX(id), 1) FROM user_auth.role), 1)
);

INSERT INTO user_auth.role (id, name, descr, alias, deleted)
SELECT nextval('user_auth.role_id_seq'),
       'CX специалист',
       'Специалист модуля Customer Experience',
       'CX_SPECIALIST',
       FALSE
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.role WHERE alias = 'CX_SPECIALIST'
);
