INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/product/api/v1/product/e2e/grouped-by-e2e',
       'GET' WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/product/api/v1/product/e2e/grouped-by-e2e' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route r
WHERE r.path_mask = '/product/api/v1/product/e2e/grouped-by-e2e'
  AND r.http_method = 'GET'
  AND NOT EXISTS (SELECT 1
                  FROM user_auth.policy p
                  WHERE p.route_id = r.id
                    AND p.role_alias IS NULL
                    AND p.permission_alias IS NULL
                    AND p.effect = 'ALLOW');


INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/product/api/v1/product/use-cases/grouped-by-use-case',
       'GET' WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/product/api/v1/product/use-cases/grouped-by-use-case' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route r
WHERE r.path_mask = '/product/api/v1/product/use-cases/grouped-by-use-case'
  AND r.http_method = 'GET'
  AND NOT EXISTS (SELECT 1
                  FROM user_auth.policy p
                  WHERE p.route_id = r.id
                    AND p.role_alias IS NULL
                    AND p.permission_alias IS NULL
                    AND p.effect = 'ALLOW');