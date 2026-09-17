INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/product/api/v2/product/{alias}/patterns/{source-type}', 'POST'
    WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/product/api/v2/product/{alias}/patterns/{source-type}' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/product/api/v2/product/{alias}/patterns/{source-type}' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);