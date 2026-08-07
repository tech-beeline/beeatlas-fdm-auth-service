-- V0016 — Add /cx/api/cx/... route masks for the cx2 gateway route.
--
-- The gateway has two generations of cx routes:
--   Old: /api-gateway/cx/v1/... (cxCj, cxBi, etc.) — covered by V0010/V0011
--   New: /cx/**  (cx2, RewritePath /cx/<seg> -> /<seg>) — not covered until now
--
-- The gateway sends the pre-rewrite path to fdm-auth, so cx2 requests arrive as
-- /cx/api/cx/v1/... which never matched /api-gateway/cx/... masks.
-- Mapping rule: /api-gateway/cx/vN/<rest> -> /cx/api/cx/vN/<rest>
--
-- Only non-trivial policies are added here. Routes with NULL/NULL/ALLOW/0/NULL
-- (any authenticated user, no checks) are already covered by the /cx/** wildcard.

-- ════════════════════════════════════════════════════════════════════
--  Wildcard fallback for cx2 (if not already registered)
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/cx/**', NULL
WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/**' AND http_method IS NULL);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/cx/**' AND http_method IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
      AND p2.role_alias IS NULL AND p2.permission_alias IS NULL
  );

-- ════════════════════════════════════════════════════════════════════
--  cx2 routes — non-trivial policies
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/product/cj/step/{id}/bi',           'GET'    WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}/bi'           AND http_method = 'GET');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/product/cj/step/{id}/bi',           'PUT'    WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}/bi'           AND http_method = 'PUT');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/product/cj/step/{id_step}/bi/{id}', 'DELETE' WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id_step}/bi/{id}' AND http_method = 'DELETE');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/library/business-interactions/{id}','GET'    WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions/{id}' AND http_method = 'GET');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v2/library/business-interactions/{id}','GET'    WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v2/library/business-interactions/{id}' AND http_method = 'GET');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/product/cj/{id}',                   'GET'    WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}'                   AND http_method = 'GET');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/library/business-interactions',     'POST'   WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions'     AND http_method = 'POST');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/product/{productId}/cj',            'POST'   WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/{productId}/cj'            AND http_method = 'POST');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/product/cj/{id}/step',              'POST'   WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}/step'              AND http_method = 'POST');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/library/business-interactions/{id}','PATCH'  WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions/{id}' AND http_method = 'PATCH');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/product/cj/{id}',                   'PUT'    WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}'                   AND http_method = 'PUT');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/product/cj/{id}',                   'PATCH'  WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}'                   AND http_method = 'PATCH');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/product/cj/step/{id}',              'PATCH'  WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}'              AND http_method = 'PATCH');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/library/business-interactions/{id}','DELETE' WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions/{id}' AND http_method = 'DELETE');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/product/cj/{id}',                   'DELETE' WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}'                   AND http_method = 'DELETE');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/product/cj/step/{id}',              'DELETE' WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}'              AND http_method = 'DELETE');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/cj/owners/reassign',                'PATCH'  WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/owners/reassign'                AND http_method = 'PATCH');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/cj/{id}',                          'GET'    WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}'                          AND http_method = 'GET');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/cj/{id}',                          'PUT'    WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}'                          AND http_method = 'PUT');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/cj/{id}',                          'PATCH'  WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}'                          AND http_method = 'PATCH');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/cj/{id}',                          'DELETE' WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}'                          AND http_method = 'DELETE');
INSERT INTO user_auth.route (path_mask, http_method) SELECT '/cx/api/cx/v1/cj/{id}/step',                     'POST'   WHERE NOT EXISTS (SELECT 1 FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}/step'                     AND http_method = 'POST');

-- ── BICJStep: DESIGN_ARTIFACT bypass OR CJ_STEP_PRODUCT_MEMBER (group 1) ─────

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}/bi' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 1    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}/bi' AND http_method = 'GET';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}/bi' AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 1    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}/bi' AND http_method = 'PUT';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id_step}/bi/{id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 1    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id_step}/bi/{id}' AND http_method = 'DELETE';

-- ── BI library GET: DESIGN_ARTIFACT bypass OR BI_PRODUCT_MEMBER (group 2) ────

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions/{id}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 2    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions/{id}' AND http_method = 'GET';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v2/library/business-interactions/{id}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 2    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v2/library/business-interactions/{id}' AND http_method = 'GET';

-- ── GET CJ/{id}: DESIGN_ARTIFACT bypass OR CJ_PRODUCT_MEMBER (group 6) ───────

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 6    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}' AND http_method = 'GET';

-- ── POST BI: DESIGN_ARTIFACT bypass OR CREATE_ARTIFACT + body productId (group 3)

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT',  'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions' AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'CREATE_ARTIFACT',  'ALLOW', 0, 3    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions' AND http_method = 'POST';

-- ── POST CJ: DESIGN_ARTIFACT bypass OR CREATE_ARTIFACT + path productId (group 7)

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/{productId}/cj' AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'CREATE_ARTIFACT', 'ALLOW', 0, 7    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/{productId}/cj' AND http_method = 'POST';

-- ── POST CJ step: DESIGN_ARTIFACT bypass OR CREATE_ARTIFACT + CJ product (group 8)

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}/step' AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'CREATE_ARTIFACT', 'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}/step' AND http_method = 'POST';

-- ── PATCH BI: DESIGN_ARTIFACT bypass OR EDIT_ARTIFACT + body+entity productId (group 4)

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions/{id}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT',   'ALLOW', 0, 4    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions/{id}' AND http_method = 'PATCH';

-- ── PUT/PATCH/DELETE CJ/{id}: DESIGN_ARTIFACT bypass OR EDIT/DELETE_ARTIFACT + CJ product (group 8)

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}' AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT',   'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}' AND http_method = 'PUT';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT',   'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}' AND http_method = 'PATCH';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT',  'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DELETE_ARTIFACT',  'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/{id}' AND http_method = 'DELETE';

-- ── PATCH/DELETE CJ step: DESIGN_ARTIFACT bypass OR EDIT/DELETE_ARTIFACT + step product (group 1)

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT',   'ALLOW', 0, 1    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}' AND http_method = 'PATCH';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT',  'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DELETE_ARTIFACT',  'ALLOW', 0, 1    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj/step/{id}' AND http_method = 'DELETE';

-- ── DELETE BI: DESIGN_ARTIFACT bypass OR DELETE_ARTIFACT + entity productId (group 5)

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT',  'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions/{id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DELETE_ARTIFACT',  'ALLOW', 0, 5    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/library/business-interactions/{id}' AND http_method = 'DELETE';

-- ── ADMINISTRATOR only: reassign CJ owners ───────────────────────────────────

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/cx/api/cx/v1/cj/owners/reassign' AND http_method = 'PATCH';

-- ── CJ (cxCj v2 paths via cx2): same policies as product/cj equivalents ──────

-- GET /cj/{id}: DESIGN_ARTIFACT bypass OR CJ_PRODUCT_MEMBER (group 6)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 6    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}' AND http_method = 'GET';

-- PUT /cj/{id}: DESIGN_ARTIFACT bypass OR EDIT_ARTIFACT + CJ product (group 8)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}' AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT',   'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}' AND http_method = 'PUT';

-- PATCH /cj/{id}: DESIGN_ARTIFACT bypass OR EDIT_ARTIFACT + CJ product (group 8)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT',   'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}' AND http_method = 'PATCH';

-- DELETE /cj/{id}: DESIGN_ARTIFACT bypass OR DELETE_ARTIFACT + CJ product (group 8)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT',  'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DELETE_ARTIFACT',  'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}' AND http_method = 'DELETE';

-- POST /cj/{id}/step: DESIGN_ARTIFACT bypass OR CREATE_ARTIFACT + CJ product (group 8)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}/step' AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'CREATE_ARTIFACT', 'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/cj/{id}/step' AND http_method = 'POST';
