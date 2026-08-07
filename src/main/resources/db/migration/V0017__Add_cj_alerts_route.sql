-- V0017 — Add literal route for GET /cx/api/cx/v1/cj/alerts.
--
-- Problem: V0016 registered /cx/api/cx/v1/cj/{id} (GET) with CJ_PRODUCT_MEMBER check
-- (group 6). AntPathMatcher matches /cx/api/cx/v1/cj/alerts against that template,
-- extracts id="alerts", and Long.parseLong("alerts") throws NumberFormatException → 400.
--
-- Fix: a literal route always wins over a template in AntPathMatcher specificity order,
-- so /cx/api/cx/v1/cj/alerts is selected before /cx/api/cx/v1/cj/{id} and the
-- numeric-parse check is never reached. The endpoint is intentionally public
-- (no user-id header required per CJController), so policy is NULL/NULL/ALLOW/0/NULL.

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/cx/api/cx/v1/cj/alerts', 'GET'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/cx/api/cx/v1/cj/alerts' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/cx/api/cx/v1/cj/alerts' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );
