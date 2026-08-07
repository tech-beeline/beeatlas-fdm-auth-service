
DELETE FROM user_auth.policy
WHERE route_id IN (
    SELECT id FROM user_auth.route
    WHERE path_mask = '/user/api/v1/users'
      AND http_method = 'POST'
)
  AND role_alias = 'ADMINISTRATOR';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/user/api/v1/users'
  AND http_method = 'POST';
