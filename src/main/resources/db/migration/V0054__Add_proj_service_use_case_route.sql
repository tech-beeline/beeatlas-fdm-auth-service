INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/project/api/v1/project/{projectId}/use-cases',
       'GET' WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/project/api/v1/project/{projectId}/use-cases' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/project/api/v1/project/ {projectId}/use-cases'
  AND http_method = 'GET'
  AND NOT EXISTS (SELECT 1
                  FROM user_auth.policy p2
                  WHERE p2.route_id = user_auth.route.id);
