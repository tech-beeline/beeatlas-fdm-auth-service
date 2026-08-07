-- V0019 — Add route for GET /product/api/v1/requirement/{id}/products.
--
-- New endpoint: returns products linked to a specific NFR version.
-- No role restriction required (same policy as GET /requirement/pattern/{id}).

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/product/api/v1/requirement/{id}/products', 'GET'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/product/api/v1/requirement/{id}/products'
      AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/product/api/v1/requirement/{id}/products'
  AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );
