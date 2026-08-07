
INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/ai-chat/api/v1/session', 'POST'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/ai-chat/api/v1/session' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/ai-chat/api/v1/session' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/ai-chat/api/v1/session/{session_key}', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/ai-chat/api/v1/session/{session_key}' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/ai-chat/api/v1/session/{session_key}' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/ai-chat/api/v1/session/{session_key}', 'DELETE'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/ai-chat/api/v1/session/{session_key}' AND http_method = 'DELETE'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/ai-chat/api/v1/session/{session_key}' AND http_method = 'DELETE'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/ai-chat/api/v1/user/{user_id}/sessions', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/ai-chat/api/v1/user/{user_id}/sessions' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/ai-chat/api/v1/user/{user_id}/sessions' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/ai-chat/api/v1/session/{session_key}/history', 'GET'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/ai-chat/api/v1/session/{session_key}/history' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/ai-chat/api/v1/session/{session_key}/history' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/ai-chat/api/v1/session/{session_key}/metadata', 'PATCH'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/ai-chat/api/v1/session/{session_key}/metadata' AND http_method = 'PATCH'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/ai-chat/api/v1/session/{session_key}/metadata' AND http_method = 'PATCH'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/ai-chat/api/v1/session/{session_key}/message', 'PATCH'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/ai-chat/api/v1/session/{session_key}/message' AND http_method = 'PATCH'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/ai-chat/api/v1/session/{session_key}/message' AND http_method = 'PATCH'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);
