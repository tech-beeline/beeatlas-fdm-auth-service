
INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/intake/import', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/intake/import' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/intake/import' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);


INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/intake/structure/start', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/intake/structure/start' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/intake/structure/start' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/intake/structure/{task_id}/progress', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/intake/structure/{task_id}/progress' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/intake/structure/{task_id}/progress' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/intake/structure/{task_id}/result', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/intake/structure/{task_id}/result' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/intake/structure/{task_id}/result' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/bc/identify/start', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/bc/identify/start' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/bc/identify/start' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/bc/identify/{task_id}/progress', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/bc/identify/{task_id}/progress' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/bc/identify/{task_id}/progress' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/bc/identify/{task_id}/result', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/bc/identify/{task_id}/result' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/bc/identify/{task_id}/result' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/tc/systems', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/tc/systems' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/tc/systems' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/tc/identify/{task_id}/progress', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/tc/identify/{task_id}/progress' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/tc/identify/{task_id}/progress' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/tc/identify/{task_id}/result', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/tc/identify/{task_id}/result' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/tc/identify/{task_id}/result' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/tc/search/{task_id}/progress', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/tc/search/{task_id}/progress' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/tc/search/{task_id}/progress' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/tc/search/{task_id}/result', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/tc/search/{task_id}/result' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/tc/search/{task_id}/result' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/tc/describe-task', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/tc/describe-task' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/tc/describe-task' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/tc/identify/start', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/tc/identify/start' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/tc/identify/start' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/tc/search', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/tc/search' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/tc/search' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/tc/search/start', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/tc/search/start' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/tc/search/start' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/publish/export', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/publish/export' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/publish/export' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/api/publish/confluence', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/api/publish/confluence' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/api/publish/confluence' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);