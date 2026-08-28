
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/project/api/v1/assessments/{id}' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/project/api/v1/project', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/project/api/v1/project' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/project/api/v1/project' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.check_type (name, description)
VALUES (
           'PROJECT_OWNER_FROM_BODY',
           'Владелец проекта: projects.project.owner_id совпадает с userId; id проекта из body (ключ param_key)'
       )
    ON CONFLICT (name) DO NOTHING;

INSERT INTO user_auth.check_group (group_id, name, check_type_id, param_key)
SELECT 13,
       'ProjectOwnerGroup',
       id,
       'projectId'
FROM user_auth.check_type
WHERE name = 'PROJECT_OWNER_FROM_BODY'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.check_group WHERE group_id = 13
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/project/api/v1/assessments', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/project/api/v1/assessments' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/project/api/v1/assessments'
  AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p
    WHERE p.route_id = user_auth.route.id
      AND p.role_alias = 'ADMINISTRATOR'
      AND p.effect = 'ALLOW'
      AND p.check_group_id IS NULL
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, 13
FROM user_auth.route
WHERE path_mask = '/project/api/v1/assessments'
  AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p
    WHERE p.route_id = user_auth.route.id
      AND p.role_alias IS NULL
      AND p.check_group_id = 13
      AND p.effect = 'ALLOW'
);