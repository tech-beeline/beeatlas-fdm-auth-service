INSERT INTO user_auth.route (path_mask, http_method)
VALUES ('/product/api/v1/product/by-aliases', 'GET');

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/product/api/v1/product/by-aliases'
  AND http_method = 'GET';