INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/product/api/v1/product', 'PUT'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/product/api/v1/product' AND http_method = 'PUT'
);

DELETE FROM user_auth.policy
WHERE route_id IN (
    SELECT id FROM user_auth.route
    WHERE path_mask = '/product/api/v1/product'
      AND http_method = 'PUT'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/product/api/v1/product'
  AND http_method = 'PUT';
