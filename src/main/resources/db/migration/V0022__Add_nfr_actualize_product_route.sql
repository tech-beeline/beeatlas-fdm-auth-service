-- V0020 — Add route for POST /product/api/v1/nfr/{id}/actual/product.
--
-- New endpoint: actualizes a manual NFR assignment on a product to the latest version.
-- No role restriction required (any authenticated user).

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/product/api/v1/nfr/{id}/actual/product', 'POST'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/product/api/v1/nfr/{id}/actual/product'
      AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/product/api/v1/nfr/{id}/actual/product'
  AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );
