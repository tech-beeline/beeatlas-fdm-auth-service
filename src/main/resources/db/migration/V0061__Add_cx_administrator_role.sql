SELECT setval(
    'user_auth.role_id_seq',
    GREATEST((SELECT COALESCE(MAX(id), 1) FROM user_auth.role), 1)
);

INSERT INTO user_auth.role (id, name, descr, alias, deleted)
SELECT nextval('user_auth.role_id_seq'),
       'Администратор СХ',
       'Администратор модуля Customer Experience',
       'CX_ADMINISTRATOR',
       FALSE
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.role WHERE alias = 'CX_ADMINISTRATOR'
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/cx/api/cx/v1/references/cj-category', 'POST'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/cx/api/cx/v1/references/cj-category' AND http_method = 'POST'
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/cx/api/cx/v1/references/cj-category/{id}', 'PATCH'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/cx/api/cx/v1/references/cj-category/{id}' AND http_method = 'PATCH'
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/cx/api/cx/v1/references/cj-category/{id}', 'DELETE'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/cx/api/cx/v1/references/cj-category/{id}' AND http_method = 'DELETE'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, role_alias, NULL, 'ALLOW', 0, NULL
FROM user_auth.route r
CROSS JOIN (VALUES ('CX_ADMINISTRATOR'), ('ADMINISTRATOR')) AS roles(role_alias)
WHERE r.path_mask = '/cx/api/cx/v1/references/cj-category'
  AND r.http_method = 'POST'
  AND NOT EXISTS (
      SELECT 1 FROM user_auth.policy p
      WHERE p.route_id = r.id
        AND p.role_alias = roles.role_alias
        AND p.permission_alias IS NULL
        AND p.effect = 'ALLOW'
  );

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, role_alias, NULL, 'ALLOW', 0, NULL
FROM user_auth.route r
CROSS JOIN (VALUES ('CX_ADMINISTRATOR'), ('ADMINISTRATOR')) AS roles(role_alias)
WHERE r.path_mask = '/cx/api/cx/v1/references/cj-category/{id}'
  AND r.http_method IN ('PATCH', 'DELETE')
  AND NOT EXISTS (
      SELECT 1 FROM user_auth.policy p
      WHERE p.route_id = r.id
        AND p.role_alias = roles.role_alias
        AND p.permission_alias IS NULL
        AND p.effect = 'ALLOW'
  );
