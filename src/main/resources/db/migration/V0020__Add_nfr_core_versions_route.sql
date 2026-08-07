-- V0018 — Add route for GET /product/api/v1/requirement/core/{core-id}/versions.
--
-- New endpoint: returns all versions of an NFR requirement by core_id.
-- No role restriction required (same policy as GET /requirement/pattern/{id}).

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/product/api/v1/requirement/core/{core-id}/versions', 'GET'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/product/api/v1/requirement/core/{core-id}/versions'
      AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/product/api/v1/requirement/core/{core-id}/versions'
  AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );
