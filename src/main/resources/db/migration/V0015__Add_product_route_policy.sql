INSERT INTO user_auth.route (path_mask, http_method)
VALUES ('/product/api/v2/requirement/version', 'POST');

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/product/api/v2/requirement/version'
  AND http_method = 'POST';