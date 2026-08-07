-- V0011 — Two structural fixes:
-- 1. cxCj gateway paths: V0010 registered product-membership checks only for
--    cxProduct paths (/api-gateway/cx/v1/product/cj/**). The cxCj gateway route
--    sends /api-gateway/cx/v1/cj/{id} — a different prefix. Added with same policies.
-- 2. Named gateway wildcards for services that had policies in V0010 but no route rows.
--    Safe because AuthorizationService now prefers the most-specific matching route:
--    when a literal or template route matches, it wins over /**. Wildcards only fire
--    as fallback when no specific route exists.
-- 3. userService2 routes with correct /user/ prefix (V0010 used wrong /api-gateway/auth/v1/).
-- 4. Correct capability named-gateway paths (V0010 used /business-capability/ and /find;
--    actual gateway sends /business/ and /search).

-- ════════════════════════════════════════════════════════════════════
--  1. cxCj paths — same policies as cxProduct equivalents in V0010
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/api-gateway/cx/v1/cj',             'GET'),
    ('/api-gateway/cx/v1/cj/{id}',        'GET'),
    ('/api-gateway/cx/v1/cj/{id}',        'PUT'),
    ('/api-gateway/cx/v1/cj/{id}',        'PATCH'),
    ('/api-gateway/cx/v1/cj/{id}',        'DELETE'),
    ('/api-gateway/cx/v1/cj/{id}/step',   'GET'),
    ('/api-gateway/cx/v1/cj/{id}/step',   'POST');

-- GET list — any authenticated user
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj' AND http_method = 'GET';

-- GET by id — DESIGN_ARTIFACT bypass OR CJ_PRODUCT_MEMBER (group 6)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/{id}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 6    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/{id}' AND http_method = 'GET';

-- PUT — DESIGN_ARTIFACT bypass OR EDIT_ARTIFACT + CJ_EDIT_PRODUCT_MEMBER (group 8)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/{id}' AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT',   'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/{id}' AND http_method = 'PUT';

-- PATCH — DESIGN_ARTIFACT bypass OR EDIT_ARTIFACT + CJ_EDIT_PRODUCT_MEMBER (group 8)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/{id}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT',   'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/{id}' AND http_method = 'PATCH';

-- DELETE — DESIGN_ARTIFACT bypass OR DELETE_ARTIFACT + CJ_EDIT_PRODUCT_MEMBER (group 8)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT',  'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/{id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DELETE_ARTIFACT',  'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/{id}' AND http_method = 'DELETE';

-- GET steps — any authenticated user
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/{id}/step' AND http_method = 'GET';

-- POST step — DESIGN_ARTIFACT bypass OR CREATE_ARTIFACT + CJ_EDIT_PRODUCT_MEMBER (group 8)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/{id}/step' AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'CREATE_ARTIFACT', 'ALLOW', 0, 8    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/{id}/step' AND http_method = 'POST';

-- ════════════════════════════════════════════════════════════════════
--  2. Named gateway wildcards (fallback: fire only when no specific route matches)
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/api-gateway/notify/v1/**',           NULL),
    ('/api-gateway/techradar/v1/**',        NULL),
    ('/api-gateway/capability/v1/**',       NULL),
    ('/api-gateway/capability/v2/**',       NULL),
    ('/api-gateway/product/v1/**',          NULL),
    ('/api-gateway/document/v1/**',         NULL),
    ('/api-gateway/document/v2/**',         NULL),
    ('/api-gateway/camunda-process/v1/**',  NULL),
    ('/api-gateway/cx/**',                  NULL),
    ('/api-gateway/pack-loader/v1/**',      NULL);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/**'          AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/**'       AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/**'      AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v2/**'      AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/product/v1/**'         AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/**'        AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v2/**'        AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/**' AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/**'                 AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v1/**'     AND http_method IS NULL;

-- ════════════════════════════════════════════════════════════════════
--  3. userService2 routes with correct /user/ prefix
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/user/api/v1/user/{id}',               'GET'),
    ('/user/api/v1/user',                    'GET'),
    ('/user/api/v1/user/role/{aliasRole}',   'GET'),
    ('/user/api/v1/users',                   'GET'),
    ('/user/api/v1/users',                   'POST'),
    ('/user/api/v1/users/myprofile',         'GET'),
    ('/user/api/v1/user/list',               'POST'),
    ('/user/api/v1/profiles/{userId}/email', 'GET'),
    ('/user/api/product/{id}/existence',     'GET'),
    ('/user/api/user/{id}/product',          'GET'),
    ('/user/api/bw/products/{login}',        'GET'),
    ('/user/api/runtime/v1/mapic/token',     'GET');

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user/{id}'               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user/role/{aliasRole}'   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/users'                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/users/myprofile'         AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user/list'               AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/profiles/{userId}/email' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/product/{id}/existence'     AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/user/{id}/product'          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/users'                AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/bw/products/{login}'     AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/runtime/v1/mapic/token' AND http_method = 'GET';

-- ════════════════════════════════════════════════════════════════════
--  4. Correct capability named-gateway paths
--     V0010 used /business-capability/ prefix; gateway sends /business/
--     V0010 used /find; gateway sends /search
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/api-gateway/capability/v1/business',                                 'GET'),
    ('/api-gateway/capability/v1/business',                                 'PUT'),
    ('/api-gateway/capability/v1/business/{id}',                            'GET'),
    ('/api-gateway/capability/v1/business/{id}/children',                   'GET'),
    ('/api-gateway/capability/v1/business/{id}/children/all',               'GET'),
    ('/api-gateway/capability/v1/business/{id}/parents',                    'GET'),
    ('/api-gateway/capability/v1/business/tree',                            'GET'),
    ('/api-gateway/capability/v1/business/tree/{id}',                       'GET'),
    ('/api-gateway/capability/v1/business/history/{id}',                    'GET'),
    ('/api-gateway/capability/v1/business/history/compare/{id}/{version}',  'GET'),
    ('/api-gateway/capability/v1/business/{code}',                          'DELETE'),
    ('/api-gateway/capability/v1/business/public/{id}',                     'POST'),
    ('/api-gateway/capability/v1/business/order',                           'POST'),
    ('/api-gateway/capability/v1/business/order/draft',                     'GET'),
    ('/api-gateway/capability/v1/business/order/draft',                     'POST'),
    ('/api-gateway/capability/v1/business/order/domains',                   'POST'),
    ('/api-gateway/capability/v1/business/order/{id}',                      'GET'),
    ('/api-gateway/capability/v1/business/order/{id}',                      'PATCH'),
    ('/api-gateway/capability/v1/business/order/draft/{id}',                'PATCH'),
    ('/api-gateway/capability/v1/tech',                                     'GET'),
    ('/api-gateway/capability/v1/tech',                                     'PUT'),
    ('/api-gateway/capability/v1/tech/{id}',                                'GET'),
    ('/api-gateway/capability/v1/tech/{id}/parents',                        'GET'),
    ('/api-gateway/capability/v1/tech/history/{id}',                        'GET'),
    ('/api-gateway/capability/v1/tech/product/{id}',                        'GET'),
    ('/api-gateway/capability/v1/tech/history/compare/{id}/{version}',      'GET'),
    ('/api-gateway/capability/v1/tech/list/by-ids',                         'GET'),
    ('/api-gateway/capability/v1/tech/by-code',                             'GET'),
    ('/api-gateway/capability/v1/tech/{code}',                              'DELETE'),
    ('/api-gateway/capability/v1/search',                                   'GET');

-- Any authenticated user
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business'                                AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business'                                AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/{id}'                           AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/{id}/children'                  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/{id}/children/all'              AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/{id}/parents'                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/tree'                           AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/tree/{id}'                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/history/{id}'                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/history/compare/{id}/{version}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/order'                          AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/order/draft'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/order/draft'                    AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/order/domains'                  AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/order/{id}'                     AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/order/{id}'                     AND http_method = 'PATCH';
-- PATCH order/draft/{id}: ADMINISTRATOR bypass OR BC_ORDER_DRAFT_OWNER (group 9)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/order/draft/{id}'    AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 9    FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/order/draft/{id}'    AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech'                                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech'                                    AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech/{id}'                               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech/{id}/parents'                       AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech/history/{id}'                       AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech/product/{id}'                       AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech/history/compare/{id}/{version}'     AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech/list/by-ids'                        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech/by-code'                            AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/search'                                  AND http_method = 'GET';

-- ADMINISTRATOR-only
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/{code}'              AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business/public/{id}'         AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech/{code}'                  AND http_method = 'DELETE';
