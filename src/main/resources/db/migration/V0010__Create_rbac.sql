CREATE TABLE user_auth.route
(
    id          BIGSERIAL    PRIMARY KEY,
    path_mask   VARCHAR(500) NOT NULL,
    http_method VARCHAR(10)  DEFAULT NULL
);

CREATE TABLE user_auth.check_type
(
    id   BIGSERIAL    PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

ALTER TABLE user_auth.check_type
    ADD CONSTRAINT "UQ_check_type_name" UNIQUE (name);

CREATE TABLE user_auth.check_group
(
    id            BIGSERIAL PRIMARY KEY,
    group_id      INTEGER   NOT NULL,
    name          VARCHAR(200),
    check_type_id BIGINT    NOT NULL REFERENCES user_auth.check_type (id)
);

CREATE INDEX "IDX_check_group_group_id" ON user_auth.check_group (group_id ASC);

CREATE TABLE user_auth.policy
(
    id               BIGSERIAL    PRIMARY KEY,
    route_id         BIGINT       NOT NULL REFERENCES user_auth.route (id),
    role_alias       VARCHAR(100) DEFAULT NULL,
    permission_alias VARCHAR(100) DEFAULT NULL,
    effect           VARCHAR(10)  NOT NULL DEFAULT 'ALLOW',
    priority         INTEGER      NOT NULL DEFAULT 0,
    check_group_id   INTEGER      DEFAULT NULL,
    CONSTRAINT "CK_policy_effect" CHECK (effect IN ('ALLOW', 'DENY'))
);

CREATE INDEX "IDX_policy_route_id"   ON user_auth.policy (route_id ASC);
CREATE INDEX "IDX_policy_role_alias" ON user_auth.policy (role_alias ASC);

INSERT INTO user_auth.check_type (name)
VALUES ('PRODUCT_MEMBER'),
       ('INDIRECT_PRODUCT_MEMBER'),
       ('AUTHOR'),
       ('OWNER');

INSERT INTO user_auth.route (path_mask, http_method)
VALUES ('/api-gateway/pack-loader/v1/package/{id}',   'GET'),
       ('/api-gateway/pack-loader/v1/packages',  'GET'),
       ('/api-gateway/pack-loader/v2/packages',  'GET');

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
VALUES (
           (SELECT id FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v1/package/{id}' AND http_method = 'GET'),
           'ADMINISTRATOR', NULL, 'ALLOW', 10, NULL
       );

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
VALUES (
           (SELECT id FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v1/packages' AND http_method = 'GET'),
           NULL, NULL, 'ALLOW', 10, NULL
       );

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
VALUES (
           (SELECT id FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v2/packages' AND http_method = 'GET'),
           NULL, NULL, 'ALLOW', 10, NULL
       );

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
VALUES (
           (SELECT id FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v1/package/{id}' AND http_method = 'GET'),
           NULL, NULL, 'DENY', 5, NULL
       );

-- V0011/V0012 stored service-side paths (/api/v1/...) which the gateway filter never sees.
-- ValidateTokenFilter is a WebFilter and runs before RewritePath, so it sees the original
-- gateway-facing path. Correct routes must use those paths.

DELETE FROM user_auth.policy
WHERE route_id IN (
    SELECT id FROM user_auth.route
    WHERE path_mask IN (
                        '/api-gateway/pack-loader/v1/package/{id}',
                        '/api-gateway/pack-loader/v1/packages',
                        '/api-gateway/pack-loader/v2/packages'
        )
);

DELETE FROM user_auth.route
WHERE path_mask IN (
                    '/api-gateway/pack-loader/v1/package/{id}',
                    '/api-gateway/pack-loader/v1/packages',
                    '/api-gateway/pack-loader/v2/packages'
    );

-- Short-path routes (/package/**)
INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         ('/api-gateway/pack-loader/v1/package/{id}',   'GET'),
                                                         ('/api-gateway/pack-loader/v1/packages',  'GET'),
                                                         ('/api-gateway/pack-loader/v2/packages',  'GET');

-- API-gateway-style routes (/api-gateway/pack-loader/v1/**)
INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         ('/api-gateway/pack-loader/v1/package/{id}', 'GET'),
                                                         ('/api-gateway/pack-loader/v1/packages',     'GET');

-- GET /package/{id} — ADMINISTRATOR only (both path styles)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 10, NULL
FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v1/package/{id}';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'DENY', 5, NULL
FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loaderpi/v1/package/{id}';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 10, NULL
FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v1/package/{id}';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'DENY', 5, NULL
FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v1/package/{id}';

-- GET /packages-list — ALLOW for all
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v1/packages';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v2/packages';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v1/packages';

-- Composite index for findByPathMaskAndHttpMethod (used on RBAC cache warm-up and admin operations)
CREATE INDEX IF NOT EXISTS "IDX_route_path_method"
    ON user_auth.route (path_mask, http_method);

-- Complements existing IDX_policy_role_alias for permission-based policy filtering
CREATE INDEX IF NOT EXISTS "IDX_policy_permission_alias"
    ON user_auth.policy (permission_alias);

-- Email lookup (used in getUserInfo fallback and user management)
CREATE INDEX IF NOT EXISTS "IDX_user_profile_email"
    ON user_auth.user_profile (email);

CREATE TABLE IF NOT EXISTS user_auth.rbac_audit_log (
                                                        id          BIGSERIAL PRIMARY KEY,
                                                        user_id     INTEGER,
                                                        method      VARCHAR(10)  NOT NULL,
    path        VARCHAR(500) NOT NULL,
    ts          TIMESTAMP    NOT NULL DEFAULT NOW()
    );

CREATE INDEX IF NOT EXISTS "IDX_rbac_audit_log_ts" ON user_auth.rbac_audit_log (ts);

INSERT INTO user_auth.route (path_mask, http_method)
VALUES
    ('/',                                              'GET'),
    ('/api-gateway/project/v1/project',                                'POST'),
    ('/api-gateway/project/v1/project/{projectId}/user/{userId}',      'POST');

-- GET / — welcome endpoint, open to all authenticated users
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
VALUES (
           (SELECT id FROM user_auth.route WHERE path_mask = '/' AND http_method = 'GET'),
           NULL, NULL, 'ALLOW', 0, NULL
       );

-- POST /api/v1/project — ADMINISTRATOR only; no matching policy = DENY by engine
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
VALUES (
           (SELECT id FROM user_auth.route WHERE path_mask = '/api-gateway/project/v1/project' AND http_method = 'POST'),
           'ADMINISTRATOR', NULL, 'ALLOW', 10, NULL
       );

-- POST /api/v1/project/{projectId}/user/{userId} — ADMINISTRATOR only
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
VALUES (
           (SELECT id FROM user_auth.route WHERE path_mask = '/api-gateway/project/v1/project/{projectId}/user/{userId}' AND http_method = 'POST'),
           'ADMINISTRATOR', NULL, 'ALLOW', 10, NULL
       );

-- Compensating migration: remove explicit catch-all DENY policies added in V0012/V0013.
-- They are now redundant: the authorization engine returns DENY when no matching policy exists.

DELETE FROM user_auth.policy
WHERE effect = 'DENY'
  AND role_alias IS NULL
  AND permission_alias IS NULL
  AND check_group_id IS NULL
  AND route_id IN (
    SELECT id FROM user_auth.route
    WHERE path_mask IN (
                        '/package/api/v1/package/{id}',
                        '/api-gateway/pack-loader/v1/package/{id}'
        )
);

-- Routes and policies for fdm-notifications-management and cx-backend.
-- GET / skipped — already registered in V0016.
--
-- param_key on check_group enables body-based parameter extraction (Jackson findValue).
-- Must be added before any check_group inserts that use it.

ALTER TABLE user_auth.check_group  ADD COLUMN param_key    VARCHAR(200) DEFAULT NULL;
ALTER TABLE user_auth.check_type   ADD COLUMN description  VARCHAR(500) DEFAULT NULL;

-- Back-fill descriptions for check types created in V0011
UPDATE user_auth.check_type SET description = 'Проверяет прямую принадлежность пользователя к продукту' WHERE name = 'PRODUCT_MEMBER';
UPDATE user_auth.check_type SET description = 'Проверяет косвенную принадлежность пользователя к продукту через связанную сущность' WHERE name = 'INDIRECT_PRODUCT_MEMBER';
UPDATE user_auth.check_type SET description = 'Проверяет, что пользователь является автором сущности' WHERE name = 'AUTHOR';
UPDATE user_auth.check_type SET description = 'Проверяет, что пользователь является владельцем сущности' WHERE name = 'OWNER';

-- ════════════════════════════════════════════════════════════════════
--  fdm-notifications-management
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method)
VALUES
    ('/api-gateway/notify/v1/business/notify',                                                         'GET'),
    ('/api-gateway/notify/v1/business/notify',                                                         'PATCH'),
    ('/api-gateway/notify/v1/subscribe/{entityType}',                                                  'GET'),
    ('/api-gateway/notify/v1/subscribe',                                                               'GET'),
    ('/api-gateway/notify/v1/subscribe/{entityType}/{id}',                                             'POST'),
    ('/api-gateway/notify/v1/subscribe/{entityType}/{id}',                                             'DELETE'),
    ('/api-gateway/notify/v1/notify',                                                                  'GET'),
    ('/api-gateway/notify/v1/notify/change-type',                                                      'GET'),
    ('/api-gateway/notify/v1/notify/entity-type',                                                      'GET'),
    ('/api-gateway/notify/v1/notify',                                                                  'PATCH'),
    ('/api-gateway/notify/v1/notify/business-event/{entity_type}/{entity_id}',                         'POST'),
    ('/api-gateway/notify/v1/notify/business-event/group/role/{role}/{entity_type}/{entity_id}',       'POST');

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/business/notify'             AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/business/notify'             AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/subscribe/{entityType}'      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/subscribe'                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/subscribe/{entityType}/{id}' AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/subscribe/{entityType}/{id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/notify'                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/notify/change-type'          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/notify/entity-type'          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/notify'                      AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/notify/business-event/{entity_type}/{entity_id}'                   AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/notify/business-event/group/role/{role}/{entity_type}/{entity_id}' AND http_method = 'POST';

-- ════════════════════════════════════════════════════════════════════
--  cx-backend — routes
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         -- BICJStep
                                                         ('/api-gateway/cx/v1/product/cj/step/{id}/bi',                                       'GET'),
                                                         ('/api-gateway/cx/v1/product/cj/step/bi/{id}',                                       'GET'),
                                                         ('/api-gateway/cx/v1/product/cj/step/{id}/bi',                                       'PUT'),
                                                         ('/api-gateway/cx/v1/product/cj/step/{id_step}/bi/{id}',                             'DELETE'),
                                                         -- BI library
                                                         ('/api-gateway/cx/v1/library/business-interactions',                                  'GET'),
                                                         ('/api-gateway/cx/v1/library/business-interactions/find',                             'GET'),
                                                         ('/api-gateway/cx/v1/library/business-interactions/{id}',                             'GET'),
                                                         ('/api-gateway/cx/v2/library/business-interactions/{id}',                             'GET'),
                                                         ('/api-gateway/cx/v1/library/business-interactions/editability/{id}',                 'GET'),
                                                         ('/api-gateway/cx/v1/library/business-interactions',                                  'POST'),
                                                         ('/api-gateway/cx/v1/library/business-interactions/{id}',                             'PATCH'),
                                                         ('/api-gateway/cx/v1/library/business-interactions/step/{id}',                        'PATCH'),
                                                         ('/api-gateway/cx/v1/library/business-interactions/step/{id}/relation',               'PATCH'),
                                                         ('/api-gateway/cx/v1/library/business-interactions/step/{id}/relation',               'PUT'),
                                                         ('/api-gateway/cx/v1/library/business-interactions/{id}',                             'DELETE'),
                                                         -- BI references
                                                         ('/api-gateway/cx/v1/references/feelings',                                            'GET'),
                                                         ('/api-gateway/cx/v1/references/bi_status',                                           'GET'),
                                                         ('/api-gateway/cx/v1/references/channels',                                            'GET'),
                                                         ('/api-gateway/cx/v1/references/participants',                                        'GET'),
                                                         -- CJ
                                                         ('/api-gateway/cx/v1/cj/alerts',                                                      'GET'),
                                                         ('/api-gateway/cx/v1/product/cj/{id}',                                                'GET'),
                                                         ('/api-gateway/cx/v1/product/cj',                                                     'GET'),
                                                         ('/api-gateway/cx/v2/product/cj',                                                     'GET'),
                                                         ('/api-gateway/cx/v2/product/cj/{id}',                                                'GET'),
                                                         ('/api-gateway/cx/v1/bpmn/cj/{id}',                                                   'PATCH'),
                                                         ('/api-gateway/cx/v1/bpmn/cj/{id}',                                                   'POST'),
                                                         ('/api-gateway/cx/v1/product/{productId}/cj',                                         'POST'),
                                                         ('/api-gateway/cx/v1/product/cj/{id}',                                                'PUT'),
                                                         ('/api-gateway/cx/v1/product/cj/{id}',                                                'PATCH'),
                                                         ('/api-gateway/cx/v1/product/cj/{id}',                                                'DELETE'),
                                                         ('/api-gateway/v1/cj/{id}',                                                           'PATCH'),
                                                         -- CJ owners
                                                         ('/api-gateway/cx/v1/cj/owners/reassign',                                             'PATCH'),
                                                         -- CJ steps
                                                         ('/api-gateway/cx/v1/product/cj/{id}/step',                                           'GET'),
                                                         ('/api-gateway/cx/v1/product/cj/step/{id}',                                           'GET'),
                                                         ('/api-gateway/cx/v1/product/cj/{id}/step',                                           'POST'),
                                                         ('/api-gateway/cx/v1/product/cj/step/{id}',                                           'PATCH'),
                                                         ('/api-gateway/cx/v1/product/cj/step/{id}',                                           'DELETE'),
                                                         -- Tech capability
                                                         ('/api-gateway/cx/v1/tech-capability/{id}/cj',                                        'GET');

-- ════════════════════════════════════════════════════════════════════
--  cx-backend — check types and groups
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.check_type (name, description)
VALUES
    ('CJ_PRODUCT_MEMBER',        'Доступ к CJ по продукту: разрешает если CJ не черновик, либо productId CJ входит в продукты пользователя (path-переменная id)'),
    ('CJ_STEP_PRODUCT_MEMBER',   'Проверяет принадлежность пользователя к продукту через шаг CJ: path-переменная id или id_step → CJ → productId'),
    ('BI_PRODUCT_MEMBER',        'Доступ к BI по продукту: разрешает если BI не черновик, либо productId BI входит в продукты пользователя (path-переменная id)'),
    ('PRODUCT_MEMBER_FROM_BODY', 'Проверяет productId из тела запроса (ключ param_key, поддерживает вложенный JSON) на принадлежность к продуктам пользователя'),
    ('BI_EDIT_PRODUCT_MEMBER',   'Проверяет, что редактируемый BI (path-переменная id) принадлежит одному из продуктов пользователя. Обязательно для операций записи');

INSERT INTO user_auth.check_group (group_id, name, check_type_id, param_key)
VALUES
    (1, 'CjStepProductGroup', (SELECT id FROM user_auth.check_type WHERE name = 'CJ_STEP_PRODUCT_MEMBER'),  NULL),
    (2, 'BiProductGroup',     (SELECT id FROM user_auth.check_type WHERE name = 'BI_PRODUCT_MEMBER'),       NULL),
    (3, 'BiBodyProductGroup', (SELECT id FROM user_auth.check_type WHERE name = 'PRODUCT_MEMBER_FROM_BODY'), 'productId'),
    -- group 4: PATCH BI — body productId AND existing entity productId must both be in user's products
    (4, 'BiPatchGroup',       (SELECT id FROM user_auth.check_type WHERE name = 'PRODUCT_MEMBER_FROM_BODY'), 'productId'),
    (4, 'BiPatchGroup',       (SELECT id FROM user_auth.check_type WHERE name = 'BI_EDIT_PRODUCT_MEMBER'),   NULL),
    -- group 5: DELETE BI — existing entity productId must be in user's products (DESIGN_ARTIFACT bypasses)
    (5, 'BiDeleteGroup',      (SELECT id FROM user_auth.check_type WHERE name = 'BI_EDIT_PRODUCT_MEMBER'),   NULL),
    -- group 6: GET CJ by id — allow if not draft, or productId in user's products (DESIGN_ARTIFACT bypasses)
    (6, 'CjProductGroup',     (SELECT id FROM user_auth.check_type WHERE name = 'CJ_PRODUCT_MEMBER'),        NULL);

-- ════════════════════════════════════════════════════════════════════
--  cx-backend — policies
-- ════════════════════════════════════════════════════════════════════

-- ── BICJStep: DESIGN_ARTIFACT OR product member (CJ_STEP_PRODUCT_MEMBER) ─────
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id}/bi'          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 1    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id}/bi'          AND http_method = 'GET';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id}/bi'          AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 1    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id}/bi'          AND http_method = 'PUT';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id_step}/bi/{id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 1    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id_step}/bi/{id}' AND http_method = 'DELETE';

-- ── BI by id: DESIGN_ARTIFACT OR product member (BI_PRODUCT_MEMBER) ──────────
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions/{id}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 2    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions/{id}' AND http_method = 'GET';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v2/library/business-interactions/{id}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 2    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v2/library/business-interactions/{id}' AND http_method = 'GET';

-- ── Read / no-permission endpoints ──────────────────────────────────────────
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/bi/{id}'                           AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions'                     AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions/find'                AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions/editability/{id}'    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions/step/{id}'           AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions/step/{id}/relation'  AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions/step/{id}/relation'  AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/references/feelings'                               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/references/bi_status'                              AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/references/channels'                               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/references/participants'                           AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/alerts'                                         AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, 6    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}'                                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj'                                        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v2/product/cj'                                        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v2/product/cj/{id}'                                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bpmn/cj/{id}'                                      AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bpmn/cj/{id}'                                      AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/v1/cj/{id}'                                              AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}/step'                              AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id}'                              AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/tech-capability/{id}/cj'                           AND http_method = 'GET';

-- ── CREATE_ARTIFACT ──────────────────────────────────────────────────────────
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'CREATE_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions' AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'CREATE_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/{productId}/cj'        AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'CREATE_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}/step'          AND http_method = 'POST';

-- POST /library/business-interactions also enforces product membership via body param
UPDATE user_auth.policy
SET check_group_id = 3
WHERE route_id = (SELECT id FROM user_auth.route
                  WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions' AND http_method = 'POST')
  AND permission_alias = 'CREATE_ARTIFACT';

-- ── EDIT_ARTIFACT ────────────────────────────────────────────────────────────
-- PATCH /library/business-interactions/{id}: body productId AND existing entity productId must be in user's products
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT', 'ALLOW', 0, 4    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions/{id}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}'                   AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}'                   AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id}'              AND http_method = 'PATCH';

-- ── DELETE_ARTIFACT ──────────────────────────────────────────────────────────
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DELETE_ARTIFACT', 'ALLOW', 0, 5    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions/{id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DELETE_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}'                    AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DELETE_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id}'               AND http_method = 'DELETE';

-- ── ADMINISTRATOR role ───────────────────────────────────────────────────────
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 10, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/owners/reassign' AND http_method = 'PATCH';

-- ── POST CJ — product membership check via path variable ────────────────────
INSERT INTO user_auth.check_type (name, description)
VALUES ('PRODUCT_MEMBER_FROM_PATH', 'Проверяет принадлежность пользователя к продукту по path-переменной (ключ param_key). DESIGN_ARTIFACT — обход.');

-- group 7: path variable productId must be in user's products
INSERT INTO user_auth.check_group (group_id, name, check_type_id, param_key)
VALUES (7, 'CjCreateProductGroup', (SELECT id FROM user_auth.check_type WHERE name = 'PRODUCT_MEMBER_FROM_PATH'), 'productId');

UPDATE user_auth.policy
SET check_group_id = 7
WHERE route_id = (SELECT id FROM user_auth.route
                  WHERE path_mask = '/api-gateway/cx/v1/product/{productId}/cj' AND http_method = 'POST')
  AND permission_alias = 'CREATE_ARTIFACT';

-- ── PUT/PATCH CJ — strict product membership check via CJ entity ─────────────
INSERT INTO user_auth.check_type (name, description)
VALUES ('CJ_EDIT_PRODUCT_MEMBER', 'Проверяет, что редактируемый CJ (path-переменная id) принадлежит одному из продуктов пользователя. DESIGN_ARTIFACT — обход. Без проверки статуса черновика.');

-- group 8: CJ productId must be in user's products (no draft bypass)
INSERT INTO user_auth.check_group (group_id, name, check_type_id, param_key)
VALUES (8, 'CjEditProductGroup', (SELECT id FROM user_auth.check_type WHERE name = 'CJ_EDIT_PRODUCT_MEMBER'), NULL);

UPDATE user_auth.policy
SET check_group_id = 8
WHERE route_id = (SELECT id FROM user_auth.route
                  WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}' AND http_method = 'PUT')
  AND permission_alias = 'EDIT_ARTIFACT';

UPDATE user_auth.policy
SET check_group_id = 8
WHERE route_id = (SELECT id FROM user_auth.route
                  WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}' AND http_method = 'PATCH')
  AND permission_alias = 'EDIT_ARTIFACT';

UPDATE user_auth.policy
SET check_group_id = 8
WHERE route_id = (SELECT id FROM user_auth.route
                  WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}' AND http_method = 'DELETE')
  AND permission_alias = 'DELETE_ARTIFACT';

-- ── CJ step write endpoints — product membership checks ─────────────────────
-- POST step: {id} = CJ id → group 8 (CjEditProductGroup)
UPDATE user_auth.policy
SET check_group_id = 8
WHERE route_id = (SELECT id FROM user_auth.route
                  WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}/step' AND http_method = 'POST')
  AND permission_alias = 'CREATE_ARTIFACT';

-- PATCH step: {id} = step id → group 1 (CjStepProductGroup)
UPDATE user_auth.policy
SET check_group_id = 1
WHERE route_id = (SELECT id FROM user_auth.route
                  WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id}' AND http_method = 'PATCH')
  AND permission_alias = 'EDIT_ARTIFACT';

-- DELETE step: {id} = step id → group 1 (CjStepProductGroup)
UPDATE user_auth.policy
SET check_group_id = 1
WHERE route_id = (SELECT id FROM user_auth.route
                  WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id}' AND http_method = 'DELETE')
  AND permission_alias = 'DELETE_ARTIFACT';

-- ── DESIGN_ARTIFACT bypass — явные строки политик для всех check-group эндпоинтов ─
-- GET CJ/{id} уже имеет check_group=6 без DESIGN_ARTIFACT строки
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}'                  AND http_method = 'GET';
-- POST BI
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions'    AND http_method = 'POST';
-- PATCH BI
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions/{id}' AND http_method = 'PATCH';
-- DELETE BI
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/library/business-interactions/{id}' AND http_method = 'DELETE';
-- POST CJ
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/{productId}/cj'            AND http_method = 'POST';
-- POST step
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}/step'              AND http_method = 'POST';
-- PATCH step
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id}'              AND http_method = 'PATCH';
-- DELETE step
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/step/{id}'              AND http_method = 'DELETE';
-- PUT CJ/{id}
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}'                  AND http_method = 'PUT';
-- PATCH CJ/{id}
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}'                  AND http_method = 'PATCH';
-- DELETE CJ/{id}
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj/{id}'                  AND http_method = 'DELETE';

-- ═══════════════════════════════════════════════════════════════════════════
-- document-service
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         ('/api-gateway/document/v1/documents/{id}',                                  'GET'),
                                                         ('/api-gateway/document/v1/documents/import',                                'GET'),
                                                         ('/api-gateway/document/v1/documents/export',                                'GET'),
                                                         ('/api-gateway/document/v1/documents/versions/{docTypeId}/{targetId}',       'GET'),
                                                         ('/api-gateway/document/v1/documents/{documentationTypeId}/{targetId}',      'GET'),
                                                         ('/api-gateway/document/v1/documents/{path_name}/{doc_type}',                'POST'),
                                                         ('/api-gateway/document/v1/documents',                                       'DELETE'),
                                                         ('/api-gateway/document/v1/import/{entityType}',                             'POST'),
                                                         ('/api-gateway/document/v1/export/{doc_id}',                                 'PATCH'),
                                                         ('/api-gateway/document/v1/export/{entity_type}',                            'POST'),
                                                         ('/api-gateway/document/v2/documents/{path_name}/{doc_type}',                'POST');

-- ADMINISTRATOR-only
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/documents/import'      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/import/{entityType}'   AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/documents'             AND http_method = 'DELETE';

-- Любой аутентифицированный пользователь
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/documents/{id}'                                  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/documents/export'                                AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/documents/versions/{docTypeId}/{targetId}'       AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/documents/{documentationTypeId}/{targetId}'      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/documents/{path_name}/{doc_type}'                AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/export/{doc_id}'                                 AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/export/{entity_type}'                            AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v2/documents/{path_name}/{doc_type}'                AND http_method = 'POST';

-- ═══════════════════════════════════════════════════════════════════════════
-- capability-backend
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         -- BusinessCapabilityController
                                                         ('/api-gateway/capability/v1/business-capability',                                  'GET'),
                                                         ('/api-gateway/capability/v1/business-capability',                                  'PUT'),
                                                         ('/api-gateway/capability/v1/business-capability/{id}',                             'GET'),
                                                         ('/api-gateway/capability/v1/business-capability/{id}/children',                    'GET'),
                                                         ('/api-gateway/capability/v1/business-capability/{id}/children/all',                'GET'),
                                                         ('/api-gateway/capability/v1/business-capability/{id}/parents',                     'GET'),
                                                         ('/api-gateway/capability/v1/business-capability/tree',                             'GET'),
                                                         ('/api-gateway/capability/v1/business-capability/tree/{id}',                        'GET'),
                                                         ('/api-gateway/capability/v1/business-capability/history/{id}',                     'GET'),
                                                         ('/api-gateway/capability/v1/business-capability/history/compare/{id}/{version}',   'GET'),
                                                         ('/api-gateway/capability/v1/business-capability/{code}',                           'DELETE'),
                                                         ('/api-gateway/capability/v1/business-capability/public/{id}',                      'POST'),
                                                         -- BusinessCapabilityOrderController
                                                         ('/api-gateway/capability/v1/business-capability/order',                            'POST'),
                                                         ('/api-gateway/capability/v1/business-capability/order/draft',                      'GET'),
                                                         ('/api-gateway/capability/v1/business-capability/order/draft',                      'POST'),
                                                         ('/api-gateway/capability/v1/business-capability/order/domains',                    'POST'),
                                                         ('/api-gateway/capability/v1/business-capability/order/{id}',                       'GET'),
                                                         ('/api-gateway/capability/v1/business-capability/order/{id}',                       'PATCH'),
                                                         ('/api-gateway/capability/v1/business-capability/order/draft/{id}',                 'PATCH'),
                                                         -- CapabilityExportController
                                                         ('/api-gateway/capability/v1/export/business-capability/{doc_id}',                  'POST'),
                                                         ('/api-gateway/capability/v1/export/tech-capability/{doc_id}',                      'POST'),
                                                         -- CapabilityMapController
                                                         ('/api-gateway/capability/v1/maps',                                                 'GET'),
                                                         ('/api-gateway/capability/v1/maps',                                                 'POST'),
                                                         ('/api-gateway/capability/v1/maps/{mapId}',                                         'GET'),
                                                         ('/api-gateway/capability/v1/maps/{mapId}',                                         'PATCH'),
                                                         ('/api-gateway/capability/v1/maps/{mapId}',                                         'DELETE'),
                                                         ('/api-gateway/capability/v1/maps/groups/{mapId}',                                  'PATCH'),
                                                         -- CapabilityMapTypesController
                                                         ('/api-gateway/capability/v1/capability/type',                                      'GET'),
                                                         -- PackageCapabilityController
                                                         ('/api-gateway/capability/v1/package-tech-capabilities',                            'POST'),
                                                         ('/api-gateway/capability/v1/package-business-capabilities',                        'POST'),
                                                         -- PromtController
                                                         ('/api-gateway/capability/v1/promt/{alias}',                                        'GET'),
                                                         ('/api-gateway/capability/v1/promt/proxy',                                          'POST'),
                                                         -- SearchCapabilityController
                                                         ('/api-gateway/capability/v1/find',                                                 'GET'),
                                                         -- SubscribeController
                                                         ('/api-gateway/capability/v1/capabilities-subscribed',                              'GET'),
                                                         -- TechCapabilityCalculateController
                                                         ('/api-gateway/capability/v1/calculate-total-tech-capabilities',                    'POST'),
                                                         ('/api-gateway/capability/v1/tech-capability/recount-quality',                      'GET'),
                                                         -- TechCapabilityController
                                                         ('/api-gateway/capability/v1/tech-capabilities',                                    'GET'),
                                                         ('/api-gateway/capability/v1/tech-capabilities',                                    'PUT'),
                                                         ('/api-gateway/capability/v1/tech-capabilities/{id}',                               'GET'),
                                                         ('/api-gateway/capability/v1/tech-capabilities/{id}/parents',                       'GET'),
                                                         ('/api-gateway/capability/v1/tech-capabilities/history/{id}',                       'GET'),
                                                         ('/api-gateway/capability/v1/tech-capabilities/product/{id}',                       'GET'),
                                                         ('/api-gateway/capability/v1/tech-capabilities/history/compare/{id}/{version}',     'GET'),
                                                         ('/api-gateway/capability/v1/tech-capabilities/list/by-ids',                        'GET'),
                                                         ('/api-gateway/capability/v1/tech-capabilities/by-code',                            'GET'),
                                                         ('/api-gateway/capability/v1/tech-capabilities/{code}',                             'DELETE'),
                                                         -- CriteriaController
                                                         ('/api-gateway/capability/v1/criterias',                                            'GET'),
                                                         ('/api-gateway/capability/v1/criterias',                                            'PUT'),
                                                         ('/api-gateway/capability/v1/criterias',                                            'POST'),
                                                         ('/api-gateway/capability/v1/criterias/{id}',                                       'DELETE');

-- check type и группа для проверки владельца черновика заявки BC
INSERT INTO user_auth.check_type (name, description)
VALUES ('BC_ORDER_DRAFT_OWNER', 'Владелец черновика заявки BC: order_owner_id совпадает с userId (path-переменная id)');

INSERT INTO user_auth.check_group (group_id, name, check_type_id, param_key)
VALUES (9, 'BcOrderDraftOwnerGroup', (SELECT id FROM user_auth.check_type WHERE name = 'BC_ORDER_DRAFT_OWNER'), NULL);

-- ADMINISTRATOR-only
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/{code}'             AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/public/{id}'        AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/calculate-total-tech-capabilities'      AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech-capability/recount-quality'        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech-capabilities/{code}'               AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/criterias'                             AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/criterias/{id}'                        AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/package-tech-capabilities'              AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/package-business-capabilities'          AND http_method = 'POST';

-- Любой аутентифицированный пользователь
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability'                               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability'                               AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/{id}'                          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/{id}/children'                 AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/{id}/children/all'             AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/{id}/parents'                  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/tree'                          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/tree/{id}'                     AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/history/{id}'                  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/history/compare/{id}/{version}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/order'                         AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/order/draft'                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/order/draft'                   AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/order/domains'                 AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/order/{id}'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/order/{id}'                    AND http_method = 'PATCH';
-- PATCH order/draft/{id}: ADMINISTRATOR bypass OR владелец черновика
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/order/draft/{id}'   AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, 9 FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/business-capability/order/draft/{id}'                 AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/export/business-capability/{doc_id}'               AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/export/tech-capability/{doc_id}'                   AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/maps'                                              AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/maps'                                              AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/maps/{mapId}'                                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/maps/{mapId}'                                      AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/maps/{mapId}'                                      AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/maps/groups/{mapId}'                               AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/capability/type'                                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/promt/{alias}'                                     AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/promt/proxy'                                       AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/find'                                              AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/capabilities-subscribed'                           AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech-capabilities'                                 AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech-capabilities'                                 AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech-capabilities/{id}'                            AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech-capabilities/{id}/parents'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech-capabilities/history/{id}'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech-capabilities/product/{id}'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech-capabilities/history/compare/{id}/{version}'  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech-capabilities/list/by-ids'                     AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/tech-capabilities/by-code'                         AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/criterias'                                         AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/criterias'                                         AND http_method = 'POST';

-- ═══════════════════════════════════════════════════════════════════════════
-- techradar-backend
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         -- TechController
                                                         ('/api-gateway/techradar/v1/tech',                                        'GET'),
                                                         ('/api-gateway/techradar/v1/tech',                                        'POST'),
                                                         ('/api-gateway/techradar/v1/tech/{id}',                                   'GET'),
                                                         ('/api-gateway/techradar/v1/tech/{id}',                                   'PATCH'),
                                                         ('/api-gateway/techradar/v1/tech/{id}',                                   'DELETE'),
                                                         ('/api-gateway/techradar/v1/tech/by-ids',                                 'GET'),
                                                         ('/api-gateway/techradar/v1/tech/subscribed',                             'GET'),
                                                         ('/api-gateway/techradar/v1/tech/product-tech',                           'GET'),
                                                         ('/api-gateway/techradar/v1/tech/product-relation',                       'POST'),
                                                         ('/api-gateway/techradar/v1/tech/{tech_id}/version',                      'POST'),
                                                         ('/api-gateway/techradar/v1/tech/{tech_id}/version/{version_id}',         'DELETE'),
                                                         ('/api-gateway/techradar/v1/tech/{tech_id}/version/{id_version}',         'PATCH'),
                                                         ('/api-gateway/techradar/v1/tech/export/{doc_id}',                        'POST'),
                                                         -- PatternController
                                                         ('/api-gateway/techradar/v1/patterns',                                    'GET'),
                                                         ('/api-gateway/techradar/v1/patterns/tech/{tech_id}',                     'GET'),
                                                         ('/api-gateway/techradar/v1/patterns/auto-check',                         'GET'),
                                                         ('/api-gateway/techradar/v1/pattern/by-ids',                              'GET'),
                                                         ('/api-gateway/techradar/v1/pattern/{id}',                                'GET'),
                                                         ('/api-gateway/techradar/v1/pattern/{id}',                                'PATCH'),
                                                         ('/api-gateway/techradar/v1/pattern/{id}',                                'DELETE'),
                                                         ('/api-gateway/techradar/v1/pattern/group',                               'GET'),
                                                         ('/api-gateway/techradar/v1/pattern/group',                               'POST'),
                                                         ('/api-gateway/techradar/v1/pattern/group/tree',                          'GET'),
                                                         ('/api-gateway/techradar/v1/pattern/group/{id}',                          'PATCH'),
                                                         ('/api-gateway/techradar/v1/pattern/group/{id}',                          'DELETE'),
                                                         ('/api-gateway/techradar/v1/pattern/chapter/{id}',                        'GET'),
                                                         ('/api-gateway/techradar/v1/pattern/availability',                        'POST'),
                                                         ('/api-gateway/techradar/v1/pattern',                                     'POST'),
                                                         -- CategoryController
                                                         ('/api-gateway/techradar/v1/category',                                    'GET'),
                                                         ('/api-gateway/techradar/v1/category',                                    'POST'),
                                                         ('/api-gateway/techradar/v1/category/tech',                               'GET'),
                                                         ('/api-gateway/techradar/v1/category/join',                               'PUT'),
                                                         ('/api-gateway/techradar/v1/category/{id}',                               'PATCH'),
                                                         ('/api-gateway/techradar/v1/category/{id}',                               'DELETE'),
                                                         -- RingController, SectorController, ProcessController
                                                         ('/api-gateway/techradar/v1/rings',                                       'GET'),
                                                         ('/api-gateway/techradar/v1/sectors',                                     'GET'),
                                                         ('/api-gateway/techradar/v1/processes',                                   'GET');

-- ADMINISTRATOR-only
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech'                                AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech/{id}'                           AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech/{id}'                           AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech/{tech_id}/version'              AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech/{tech_id}/version/{version_id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech/{tech_id}/version/{id_version}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern'                             AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern/{id}'                        AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern/{id}'                        AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern/group'                       AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern/group/{id}'                  AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern/group/{id}'                  AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/category'                            AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/category/join'                       AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/category/{id}'                       AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/category/{id}'                       AND http_method = 'DELETE';

-- Любой аутентифицированный пользователь
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech'                             AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech/{id}'                        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech/by-ids'                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech/subscribed'                  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech/product-tech'                AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech/product-relation'            AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/tech/export/{doc_id}'             AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/patterns'                         AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/patterns/tech/{tech_id}'          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/patterns/auto-check'              AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern/by-ids'                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern/{id}'                     AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern/group'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern/group/tree'               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern/chapter/{id}'             AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/pattern/availability'             AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/category'                         AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/category/tech'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/rings'                            AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/sectors'                          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/processes'                        AND http_method = 'GET';

-- ═══════════════════════════════════════════════════════════════════════════
-- fdm-bpm
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         -- CamundaApplicationController
                                                         ('/api-gateway/camunda-process/v1/application/nobody',                                               'GET'),
                                                         ('/api-gateway/camunda-process/v1/application/author',                                               'GET'),
                                                         ('/api-gateway/camunda-process/v1/application/executor',                                             'GET'),
                                                         ('/api-gateway/camunda-process/v1/application',                                                      'GET'),
                                                         ('/api-gateway/camunda-process/v1/application/{business_key}',                                       'GET'),
                                                         ('/api-gateway/camunda-process/v1/application/{business_key}/executor',                              'PATCH'),
                                                         ('/api-gateway/camunda-process/v1/application/{business_key}/executor/{new_executor_id}',            'PATCH'),
                                                         ('/api-gateway/camunda-process/v1/application/{business_key}/change-status/{status_alias}',          'PATCH'),
                                                         ('/api-gateway/camunda-process/v1/application/{business_key}/sync-order',                            'PATCH'),
                                                         -- CamundaProcessController
                                                         ('/api-gateway/camunda-process/v1/status/{id_enum}/{id}/now',                                        'GET'),
                                                         ('/api-gateway/camunda-process/v1/status/{id_enum}/{id}',                                            'GET'),
                                                         ('/api-gateway/camunda-process/v1/processes/context/{name}/{value}',                                 'GET'),
                                                         ('/api-gateway/camunda-process/v1/processes/{id}',                                                   'GET'),
                                                         -- PipelineController
                                                         ('/api-gateway/camunda-process/v1/pipeline/process-status',                                                          'GET');

-- check types и группы для проверок fdm-bpm
INSERT INTO user_auth.check_type (name, description)
VALUES ('APPLICATION_AUTHOR_OR_EXECUTOR', 'Автор или исполнитель заявки: authorId или executorId совпадает с userId (path-переменная business_key)');

INSERT INTO user_auth.check_type (name, description)
VALUES ('APPLICATION_CURRENT_EXECUTOR', 'Текущий исполнитель заявки: executorId совпадает с userId (path-переменная business_key)');

INSERT INTO user_auth.check_group (group_id, name, check_type_id, param_key)
VALUES (10, 'ApplicationAuthorOrExecutorGroup', (SELECT id FROM user_auth.check_type WHERE name = 'APPLICATION_AUTHOR_OR_EXECUTOR'), NULL);

INSERT INTO user_auth.check_group (group_id, name, check_type_id, param_key)
VALUES (11, 'ApplicationCurrentExecutorGroup', (SELECT id FROM user_auth.check_type WHERE name = 'APPLICATION_CURRENT_EXECUTOR'), NULL);

-- Любой аутентифицированный пользователь
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/application/nobody'                                               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/application/author'                                               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/application/executor'                                             AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/application'                                                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}'                                       AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}/executor'                              AND http_method = 'PATCH';
-- change-status: ADMINISTRATOR bypass OR автор/исполнитель заявки
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}/change-status/{status_alias}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, 10 FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}/change-status/{status_alias}'            AND http_method = 'PATCH';
-- executor/{new_executor_id}: ADMINISTRATOR bypass OR текущий исполнитель
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}/executor/{new_executor_id}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, 11 FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}/executor/{new_executor_id}'              AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}/sync-order'                            AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/status/{id_enum}/{id}/now'                                        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/status/{id_enum}/{id}'                                            AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/processes/context/{name}/{value}'                                 AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/processes/{id}'                                                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/pipeline/process-status'                                                          AND http_method = 'GET';

-- ═══════════════════════════════════════════════════════════════════════════
-- fdm-products
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         -- ProductController
                                                         ('/product/api/v1/user/product',                                              'GET'),
                                                         ('/product/api/v1/user/product/admin',                                        'GET'),
                                                         ('/product/api/v1/user/{id}/products',                                        'POST'),
                                                         ('/product/api/v1/product/infra',                                             'GET'),
                                                         ('/product/api/v1/product/infra/contains',                                    'GET'),
                                                         ('/product/api/v1/product/infra/search',                                      'GET'),
                                                         ('/product/api/v1/product/by-ids',                                            'GET'),
                                                         ('/product/api/v1/product/info',                                              'GET'),
                                                         ('/product/api/v1/product/parent',                                            'GET'),
                                                         ('/product/api/v1/product/api-secret/{api-key}',                              'GET'),
                                                         ('/product/api/v1/service/api-secret/{api-key}',                              'GET'),
                                                         ('/product/api/v1/product/implemented/container/tech-capability',             'GET'),
                                                         ('/product/api/v1/products/relations/tech',                                   'GET'),
                                                         ('/product/api/v1/products/mnemonic',                                         'GET'),
                                                         ('/product/api/v1/product/{code}',                                            'GET'),
                                                         ('/product/api/v1/product/{code}/info',                                       'GET'),
                                                         ('/product/api/v2/product/{code}/info',                                       'GET'),
                                                         ('/product/api/v1/product/{id}/availability',                                 'GET'),
                                                         ('/product/api/v1/product/{id}/tc-implementation',                            'GET'),
                                                         ('/product/api/v1/product/{id}/structurizr-key',                              'GET'),
                                                         ('/product/api/v1/product/{cmdb}/influence',                                  'GET'),
                                                         ('/product/api/v1/product/{cmdb}/interface/arch',                             'GET'),
                                                         ('/product/api/v1/product/{cmdb}/interface/mapic',                            'GET'),
                                                         ('/product/api/v1/product/{cmdb}/container',                                  'GET'),
                                                         ('/product/api/v1/product/{cmdb}/e2e',                                        'GET'),
                                                         ('/product/api/v1/product/{alias}/free',                                      'GET'),
                                                         ('/product/api/v1/product/{alias}/employee',                                  'GET'),
                                                         ('/product/api/v1/product/{alias}/fitness-function',                          'GET'),
                                                         ('/product/api/v1/product/{alias}/patterns',                                  'GET'),
                                                         ('/product/api/v1/product/{alias}/fitness-function/{source_type}',            'POST'),
                                                         ('/product/api/v1/product/{alias}/patterns/{source-type}',                    'POST'),
                                                         ('/product/api/v1/product/{code}',                                            'PUT'),
                                                         ('/product/api/v1/product/{code}/relations',                                  'PUT'),
                                                         ('/product/api/v1/product',                                                   'PUT'),
                                                         ('/product/api/v1/product/{code}/workspace',                                  'PATCH'),
                                                         ('/product/api/v1/product/{cmdb}/source',                                     'PATCH'),
                                                         ('/product/api/v1/product/{id}',                                              'DELETE'),
                                                         -- NfrController
                                                         ('/product/api/v1/nfr',                                                       'GET'),
                                                         ('/product/api/v1/nfr/{id}',                                                  'GET'),
                                                         ('/product/api/v1/nfr/product',                                               'GET'),
                                                         ('/product/api/v1/nfr/product',                                               'POST'),
                                                         ('/product/api/v1/nfr/product/relations',                                     'DELETE'),
                                                         ('/product/api/v1/nfr/{req-id}/product',                                      'DELETE'),
                                                         ('/product/api/v1/nfr/pattern/{id}',                                          'POST'),
                                                         -- ChapterController
                                                         ('/product/api/v1/chapter',                                                   'GET'),
                                                         ('/product/api/v1/chapter/{id}/patterns',                                     'GET'),
                                                         ('/product/api/v1/chapter',                                                   'POST'),
                                                         ('/product/api/v1/chapter',                                                   'PATCH'),
                                                         -- InterfaceController
                                                         ('/product/api/v1/connection/interface',                                      'POST'),
                                                         -- RequirementController
                                                         ('/product/api/v1/requirement/pattern/{id}',                                  'GET'),
                                                         ('/product/api/v1/requirement',                                               'POST'),
                                                         ('/product/api/v1/requirement/version',                                       'POST'),
                                                         -- ProductTechRelationController
                                                         ('/product/api/v1/product-tech-relation',                                     'GET'),
                                                         ('/product/api/v1/product-tech-relation/{techId}',                            'POST'),
                                                         ('/product/api/v1/product-tech-relation/{techId}/{productId}',                'DELETE'),
                                                         -- TechController
                                                         ('/product/api/v1/tech/{techId}/product',                                     'GET'),
                                                         -- SearchController
                                                         ('/product/api/v1/operation',                                                 'GET'),
                                                         ('/product/api/v1/operation/tech-capability/{id}',                            'GET'),
                                                         ('/product/api/v1/operation/tech-capability/{id}/tree',                       'GET'),
                                                         -- SourceMetricController
                                                         ('/product/api/v1/source-metric',                                             'GET'),
                                                         ('/product/api/v1/source-metric',                                             'PUT'),
                                                         -- DiscoveredInterfaceController
                                                         ('/product/api/v1/discovered-interfaces',                                     'PUT'),
                                                         ('/product/api/v1/discovered-interface/{id}/operations',                      'PUT'),
                                                         ('/product/api/v1/discovered-interface',                                      'GET'),
                                                         -- Mproduct/apicController
                                                         ('/product/api/v1/mapic/product/{cmdb}/published-api',                        'GET'),
                                                         ('/product/api/v1/mapic/spec/{api-id}',                                       'GET'),
                                                         -- PatternProductController
                                                         ('/product/api/v1/pattern/product',                                           'GET'),
                                                         -- FitnessFunctionController
                                                         ('/product/api/v1/dashboard/fitness-function',                                'GET'),
                                                         ('/product/api/v1/ff',                                                        'GET');

-- check_group для проверки членства пользователя в команде продукта по path-переменной id
INSERT INTO user_auth.check_group (group_id, name, check_type_id, param_key)
VALUES (12, 'ProductMemberByIdGroup', (SELECT id FROM user_auth.check_type WHERE name = 'PRODUCT_MEMBER_FROM_PATH'), 'id');

-- ADMINISTRATOR-only
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product'          AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{id}'     AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/chapter'          AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/chapter'          AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/requirement'      AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/requirement/version' AND http_method = 'POST';

-- structurizr-key: ADMINISTRATOR bypass OR член команды продукта
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{id}/structurizr-key' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, 12 FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{id}/structurizr-key' AND http_method = 'GET';

-- Любой аутентифицированный пользователь
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/user/product'                                        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/user/product/admin'                                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/user/{id}/products'                                   AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/infra'                                        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/infra/contains'                               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/infra/search'                                 AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/by-ids'                                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/info'                                        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/parent'                                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/api-secret/{api-key}'                        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api/v1/service/api-secret/{api-key}'                        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/implemented/container/tech-capability'        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/products/relations/tech'                             AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/products/mnemonic'                                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{code}'                                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{code}/info'                                 AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v2/product/{code}/info'                                 AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{id}/availability'                           AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{id}/tc-implementation'                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{cmdb}/influence'                            AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{cmdb}/interface/arch'                       AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{cmdb}/interface/mapic'                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{cmdb}/container'                            AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{cmdb}/e2e'                                  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{alias}/free'                                AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{alias}/employee'                            AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{alias}/fitness-function'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{alias}/patterns'                            AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{alias}/fitness-function/{source_type}'      AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{alias}/patterns/{source-type}'              AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{code}'                                      AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{code}/relations'                            AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{code}/workspace'                            AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product/{cmdb}/source'                               AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/nfr'                                                 AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/nfr/{id}'                                            AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/nfr/product'                                         AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/nfr/product'                                         AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/nfr/product/relations'                               AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/nfr/{req-id}/product'                                AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/nfr/pattern/{id}'                                    AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/chapter'                                             AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/chapter/{id}/patterns'                               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/connection/interface'                                AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/requirement/pattern/{id}'                            AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product-tech-relation'                               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product-tech-relation/{techId}'                      AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/product-tech-relation/{techId}/{productId}'           AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/tech/{techId}/product'                               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/operation'                                           AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/operation/tech-capability/{id}'                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/operation/tech-capability/{id}/tree'                 AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/source-metric'                                       AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/source-metric'                                       AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/discovered-interfaces'                               AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/discovered-interface/{id}/operations'                AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/discovered-interface'                                AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/mapic/product/{cmdb}/published-api'                  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/mapic/spec/{api-id}'                                 AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/pattern/product'                                     AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/dashboard/fitness-function'                          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/api/v1/ff'                                                  AND http_method = 'GET';

-- Routes and policies for fdm-auth itself.
-- Gateway sends the ORIGINAL path (before RewritePath) to /api/v1/authorize:
--   userService  (path.auth = /api-gateway/auth/v1)  → paths below with that prefix
--   userService2 (path.user2 = /user)                → paths below with /user prefix

-- ════════════════════════════════════════════════════════════════════
--  userService — /api-gateway/auth/v1/**
-- ════════════════════════════════════════════════════════════════════

-- AdminUserController (/api/admin/v1/user)
INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         ('/api-gateway/auth/v1/user',                       'GET'),
                                                         ('/api-gateway/auth/v1/user/find',                  'GET'),
                                                         ('/api-gateway/auth/v1/user/{login}',               'GET'),
                                                         ('/api-gateway/auth/v1/user/{login}/roles',         'GET'),
                                                         ('/api-gateway/auth/v1/user/{login}/permissions',   'GET'),
                                                         ('/api-gateway/auth/v1/user/{login}/roles',         'PUT'),
                                                         ('/api-gateway/auth/v1/user/{id}/existence',        'GET'),
                                                         ('/api-gateway/auth/v1/user/{id}/user-info',        'GET'),
                                                         ('/api-gateway/auth/v1/user/{login}/info',          'GET');

-- RoleController (/api/admin/v1/roles)
INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         ('/api-gateway/auth/v1/roles',                      'GET'),
                                                         ('/api-gateway/auth/v1/roles',                      'POST'),
                                                         ('/api-gateway/auth/v1/roles',                      'PATCH'),
                                                         ('/api-gateway/auth/v1/roles/{id}',                 'GET'),
                                                         ('/api-gateway/auth/v1/roles/{id}',                 'DELETE'),
                                                         ('/api-gateway/auth/v1/roles/{id}/permissions',     'GET'),
                                                         ('/api-gateway/auth/v1/roles/{id}/permissions',     'PUT');

-- PermissionController (/api/admin/v1/permissions)
INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/api-gateway/auth/v1/permissions',                'GET');

-- ProductController (/api/admin/v1/product)
INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/api-gateway/auth/v1/product',                    'GET');

-- RbacController (/api/admin/v1/rbac)
INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         ('/api-gateway/auth/v1/rbac/policy',                'GET'),
                                                         ('/api-gateway/auth/v1/rbac/policy/{id}',           'GET'),
                                                         ('/api-gateway/auth/v1/rbac/policy',                'POST'),
                                                         ('/api-gateway/auth/v1/rbac/policy/{id}',           'PUT'),
                                                         ('/api-gateway/auth/v1/rbac/policy/{id}',           'DELETE'),
                                                         ('/api-gateway/auth/v1/rbac/check-type',            'GET'),
                                                         ('/api-gateway/auth/v1/rbac/export',                'GET'),
                                                         ('/api-gateway/auth/v1/rbac/import',                'POST');

-- ════════════════════════════════════════════════════════════════════
--  Policies — /api-gateway/auth/v1/**
-- ════════════════════════════════════════════════════════════════════

-- Любой аутентифицированный пользователь
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/user/{login}/info'        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/user/{id}/existence'      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/user/{id}/user-info'      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/user/{login}/roles'       AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/product'                  AND http_method = 'GET';

-- ADMINISTRATOR-only
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/user'                          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/user/find'                      AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/user/{login}'                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/user/{login}/permissions'        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/user/{login}/roles'              AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/roles'                          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/roles'                          AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/roles'                          AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/roles/{id}'                     AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/roles/{id}'                     AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/roles/{id}/permissions'          AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/roles/{id}/permissions'          AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/permissions'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/rbac/policy'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/rbac/policy/{id}'               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/rbac/policy'                    AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/rbac/policy/{id}'               AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/rbac/policy/{id}'               AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/rbac/check-type'                AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/rbac/export'                    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/auth/v1/rbac/import'                    AND http_method = 'POST';

-- ════════════════════════════════════════════════════════════════════
--  userService2 — /user/** (direct passthrough, strips /user prefix)
-- ════════════════════════════════════════════════════════════════════

-- UserController (/api/v1/user*, /api/v1/users*)
INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         ('/api-gateway/auth/v1/user/{id}',              'GET'),
                                                         ('/api-gateway/auth/v1/user',                   'GET'),
                                                         ('/api-gateway/auth/v1/user/role/{aliasRole}',  'GET'),
                                                         ('/api-gateway/auth/v1/users',                  'GET'),
                                                         ('/api-gateway/auth/v1/users',                  'POST'),
                                                         ('/api-gateway/auth/v1/users/myprofile',        'GET'),
                                                         ('/api-gateway/auth/v1/user/list',              'POST');

-- ProfileController (/api/v1/profiles)
INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/user/api/v1/profiles/{userId}/email', 'GET');

-- ProductController (/api/product, /api/user)
INSERT INTO user_auth.route (path_mask, http_method) VALUES
                                                         ('/user/api/product/{id}/existence',    'GET'),
                                                         ('/user/api/user/{id}/product',         'GET');

-- BeeWorksController (/api/bw)
INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/user/api/bw/products/{login}',       'GET');

-- ConfigurationController
INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/user/api/runtime/v1/mapic/token',    'GET');

-- ════════════════════════════════════════════════════════════════════
--  Policies — /user/**
-- ════════════════════════════════════════════════════════════════════

-- Любой аутентифицированный пользователь
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user/{id}'             AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user'                  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user/role/{aliasRole}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/users'                 AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/users/myprofile'       AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user/list'             AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/profiles/{userId}/email' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/product/{id}/existence'   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/user/{id}/product'        AND http_method = 'GET';

-- ADMINISTRATOR-only
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/users'                  AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/bw/products/{login}'       AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/runtime/v1/mapic/token'    AND http_method = 'GET';


-- ════════════════════════════════════════════════════════════════════
--  Named gateway routes  (/api-gateway/<service>/v1/**)
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/api-gateway/structurizr/v1/**',      NULL),
    ('/api-gateway/graph/v1/**',            NULL);

-- ════════════════════════════════════════════════════════════════════
--  Direct passthrough routes  (/<prefix>/**)
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/notification/**',        NULL),
    ('/techradar/**',           NULL),
    ('/capability/**',          NULL),
    ('/product/**',             NULL),
    ('/cx/**',                  NULL),
    ('/doc/**',                 NULL),
    ('/camunda/**',             NULL),
    ('/package/**',             NULL),
    ('/ff/**',                  NULL),
    ('/arch-graph/**',          NULL),
    ('/architecture-center/**', NULL),
    ('/structurizr-backend/**', NULL),
    ('/dashboard/**',           NULL),
    ('/ambassador/**',          NULL),
    ('/obs-dashboard/**',       NULL),
    ('/sequence-backend/**',    NULL),
    ('/dashboard-service/**',   NULL),
    ('/staging-sequence/**',    NULL),
    ('/graph-validator/**',     NULL);

-- ════════════════════════════════════════════════════════════════════
--  Policies — any authenticated user for all routes above
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/**'           AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/**'        AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/**'       AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v2/**'       AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/product/v1/**'          AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/**'         AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v2/**'         AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/**'  AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/**'                  AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/structurizr/v1/**'      AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/graph/v1/**'            AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v1/**'      AND http_method IS NULL;

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/notification/**'        AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/techradar/**'           AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/capability/**'          AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/product/**'             AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/**'                  AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/doc/**'                 AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/camunda/**'             AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/package/**'             AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/ff/**'                  AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/arch-graph/**'          AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/architecture-center/**' AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/structurizr-backend/**' AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/dashboard/**'           AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/ambassador/**'          AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/obs-dashboard/**'       AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/sequence-backend/**'    AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/dashboard-service/**'   AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/staging-sequence/**'    AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/graph-validator/**'     AND http_method IS NULL;

INSERT INTO user_auth.route (path_mask, http_method) VALUES ('/user/api/v1/users', 'POST');
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/users' AND http_method = 'POST';

-- V0020 — Missing gateway-prefix routes.
-- Root cause: V0010 inserted policies for named-gateway wildcards but forgot
-- to insert the route entries themselves (only /api-gateway/structurizr/v1/**
-- and /api-gateway/graph/v1/** were added). Policy SELECTs returned 0 rows,
-- so no policy was ever stored. Additionally, V0010 inserted userService2
-- routes with the wrong /api-gateway/auth/v1/ prefix instead of /user/,
-- so policies for /user/api/v1/... paths were also silently dropped.

-- ════════════════════════════════════════════════════════════════════
--  Named gateway wildcards (V0010 inserted policies but not routes)
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
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/notify/v1/**'           AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/techradar/v1/**'        AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v1/**'       AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/capability/v2/**'       AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/product/v1/**'          AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v1/**'         AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/document/v2/**'         AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/camunda-process/v1/**'  AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/**'                  AND http_method IS NULL;
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/pack-loader/v1/**'      AND http_method IS NULL;

-- ════════════════════════════════════════════════════════════════════
--  userService2 routes missing due to wrong prefix in V0010
--  V0010 inserted /api-gateway/auth/v1/users/myprofile instead of
--  /user/api/v1/users/myprofile, so policies silently inserted 0 rows.
--  Only "any authenticated user" routes — ADMINISTRATOR-only ones
--  (POST /users, GET /bw/products, GET /runtime/mapic/token) stay in V0019.
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/user/api/v1/user/{id}',              'GET'),
    ('/user/api/v1/user',                   'GET'),
    ('/user/api/v1/user/role/{aliasRole}',  'GET'),
    ('/user/api/v1/users',                  'GET'),
    ('/user/api/v1/users/myprofile',        'GET'),
    ('/user/api/v1/user/list',              'POST'),
    ('/user/api/v1/profiles/{userId}/email','GET'),
    ('/user/api/product/{id}/existence',    'GET'),
    ('/user/api/user/{id}/product',         'GET');

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user/{id}'              AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user'                   AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user/role/{aliasRole}'  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/users'                  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/users/myprofile'        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/user/list'              AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/v1/profiles/{userId}/email' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/product/{id}/existence'    AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/user/{id}/product'         AND http_method = 'GET';
