-- V0040 — SFDM-4092: register the v2 e2e endpoints (E2eV2Controller, /api/v2/e2e), which were
-- never added to fdm-auth (only the v1 siblings were, in V0025). Without a route+policy here,
-- AuthorizationService.authorize() denies by default for any unmatched (path, method) — see
-- AuthorizationService.java:129-134 — so every one of these currently 403s through the real
-- gateway/auth flow, including the pre-existing POST that the frontend already relies on.
--
-- Same "any authenticated user" policy as the v1 e2e routes (V0025) — no dedicated e2e-owner
-- role exists yet.

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/product/api/v2/e2e', 'POST'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/product/api/v2/e2e' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/product/api/v2/e2e' AND http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/product/api/v2/e2e/{code}', 'GET'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/product/api/v2/e2e/{code}' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/product/api/v2/e2e/{code}' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/product/api/v2/e2e/{code}', 'PATCH'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/product/api/v2/e2e/{code}' AND http_method = 'PATCH'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/product/api/v2/e2e/{code}' AND http_method = 'PATCH'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );
