-- ════════════════════════════════════════════════════════════════════
-- SFDM-T604: убрать ADMINISTRATOR bypass для переназначения исполнителя.
-- Только текущий исполнитель (check_group=11) может переназначить заявку.
-- ════════════════════════════════════════════════════════════════════
DELETE FROM user_auth.policy
WHERE route_id = (
    SELECT id FROM user_auth.route
    WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}/executor/{new_executor_id}'
      AND http_method = 'PATCH'
)
  AND role_alias = 'ADMINISTRATOR'
  AND check_group_id IS NULL;

-- ════════════════════════════════════════════════════════════════════
-- SFDM-T563: change-status доступен любому аутентифицированному пользователю.
-- Убрать ADMINISTRATOR bypass и проверку автора/исполнителя (check_group=10).
-- ════════════════════════════════════════════════════════════════════
DELETE FROM user_auth.policy
WHERE route_id = (
    SELECT id FROM user_auth.route
    WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}/change-status/{status_alias}'
      AND http_method = 'PATCH'
)
  AND (
      (role_alias = 'ADMINISTRATOR' AND check_group_id IS NULL)
   OR (role_alias IS NULL          AND check_group_id = 10)
  );

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}/change-status/{status_alias}'
  AND http_method = 'PATCH';

-- ════════════════════════════════════════════════════════════════════
-- Кейс 3: GET /user/api/admin/v1/user → 403 даже для ADMINISTRATOR.
-- V0011 добавил /user/api/v1/... роуты, но пропустил admin-эндпоинты.
-- Gateway: userService2 (/user/**) → реврайт в /{segment}, fdm-auth
-- видит оригинальный путь /user/api/admin/v1/user.
-- ════════════════════════════════════════════════════════════════════
INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/user/api/admin/v1/user',              'GET'),
    ('/user/api/admin/v1/user/find',         'GET'),
    ('/user/api/admin/v1/user/{login}',      'GET'),
    ('/user/api/admin/v1/user/{login}/roles','GET'),
    ('/user/api/admin/v1/user/{login}/roles','PUT');

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/admin/v1/user'               AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/admin/v1/user/find'           AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/admin/v1/user/{login}'        AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/admin/v1/user/{login}/roles'  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/user/api/admin/v1/user/{login}/roles'  AND http_method = 'PUT';

-- ════════════════════════════════════════════════════════════════════
-- Кейс 4: PUT /capability/api/v1/criterias → 200 для не-администратора.
-- Gateway: capabilityService2 (/capability/**) → реврайт в /{segment}.
-- fdm-auth видит /capability/api/v1/criterias — роута нет,
-- а зарегистрированный /api-gateway/capability/v1/criterias не совпадает.
-- Добавляем роуты под /capability/api/v1/ с корректными политиками.
-- ════════════════════════════════════════════════════════════════════
INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/capability/api/v1/criterias',      'GET'),
    ('/capability/api/v1/criterias',      'PUT'),
    ('/capability/api/v1/criterias',      'POST'),
    ('/capability/api/v1/criterias/{id}', 'DELETE');

-- GET и POST — любой аутентифицированный пользователь
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/capability/api/v1/criterias' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/capability/api/v1/criterias' AND http_method = 'POST';

-- PUT и DELETE — только ADMINISTRATOR
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/capability/api/v1/criterias'      AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/capability/api/v1/criterias/{id}' AND http_method = 'DELETE';

-- ════════════════════════════════════════════════════════════════════════
-- T300 — BI library routes via cxBi gateway (/api-gateway/cx/v1/bi/**)
-- V0010 registered routes under /api-gateway/cx/v1/library/business-interactions
-- but cxBi sends /api-gateway/cx/v1/bi/** → no match → wildcard ALLOW fires.
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/api-gateway/cx/v1/bi',                   'GET'),
    ('/api-gateway/cx/v1/bi',                   'POST'),
    ('/api-gateway/cx/v1/bi/find',              'GET'),
    ('/api-gateway/cx/v1/bi/{id}',              'GET'),
    ('/api-gateway/cx/v1/bi/{id}',              'PATCH'),
    ('/api-gateway/cx/v1/bi/{id}',              'DELETE'),
    ('/api-gateway/cx/v1/bi/editability/{id}',  'GET'),
    ('/api-gateway/cx/v2/bi/{id}',              'GET');

-- GET list / find / editability — any authenticated user
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bi'                  AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bi/find'             AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bi/editability/{id}' AND http_method = 'GET';

-- GET /{id} — DESIGN_ARTIFACT bypass OR BI_PRODUCT_MEMBER (group 2)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bi/{id}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 2    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bi/{id}' AND http_method = 'GET';

-- POST — DESIGN_ARTIFACT bypass OR CREATE_ARTIFACT + product from body (group 3)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bi' AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'CREATE_ARTIFACT', 'ALLOW', 0, 3    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bi' AND http_method = 'POST';

-- PATCH /{id} — DESIGN_ARTIFACT bypass OR EDIT_ARTIFACT + BiPatchGroup (group 4)
-- group 4 = AND(PRODUCT_MEMBER_FROM_BODY(productId), BI_EDIT_PRODUCT_MEMBER)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bi/{id}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT',   'ALLOW', 0, 4    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bi/{id}' AND http_method = 'PATCH';

-- DELETE /{id} — DESIGN_ARTIFACT bypass OR DELETE_ARTIFACT + BiDeleteGroup (group 5)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT',  'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bi/{id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DELETE_ARTIFACT',  'ALLOW', 0, 5    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/bi/{id}' AND http_method = 'DELETE';

-- V2 GET /{id}
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v2/bi/{id}' AND http_method = 'GET';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 2    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v2/bi/{id}' AND http_method = 'GET';

-- ════════════════════════════════════════════════════════════════════════
-- T301 — PUT /api-gateway/cx/v1/cj/step/{id}/bi (attach BI to CJ step)
-- cxCj route sends this path; V0010 only registered /product/cj/step/{id}/bi.
-- T301 DELETE: route existed but CheckStrategyExecutor picked pathVars["id"] (BI id)
-- instead of pathVars["id_step"] (step id) → fixed in Java code, no migration needed.
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/api-gateway/cx/v1/cj/step/{id}/bi', 'PUT');

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/step/{id}/bi' AND http_method = 'PUT';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL,              'ALLOW', 0, 1    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/step/{id}/bi' AND http_method = 'PUT';

-- ════════════════════════════════════════════════════════════════════════
-- T303 — CJ step write routes via cxCj (/api-gateway/cx/v1/cj/**)
-- V0010 registered /product/cj/step/{id} PATCH+DELETE (cxProduct route).
-- cxCj sends /api-gateway/cx/v1/cj/step/{id} → no match → wildcard ALLOW.
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/api-gateway/cx/v1/cj/step/{id}', 'PATCH'),
    ('/api-gateway/cx/v1/cj/step/{id}', 'DELETE');

-- PATCH — DESIGN_ARTIFACT bypass OR EDIT_ARTIFACT + CjStepProductGroup (group 1)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/step/{id}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'EDIT_ARTIFACT',   'ALLOW', 0, 1    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/step/{id}' AND http_method = 'PATCH';

-- DELETE — DESIGN_ARTIFACT bypass OR DELETE_ARTIFACT + CjStepProductGroup (group 1)
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT',  'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/step/{id}' AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DELETE_ARTIFACT',  'ALLOW', 0, 1    FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/cj/step/{id}' AND http_method = 'DELETE';

-- ════════════════════════════════════════════════════════════════════════
-- Pattern POST via technoradar2 (/techradar/** → /{segment})
-- V0010 has /api-gateway/techradar/v1/pattern (POST) ADMINISTRATOR-only.
-- Access via technoradar2 sends /techradar/api/v1/pattern → no match → DENY → 403.
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/techradar/api/v1/pattern', 'POST');

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/techradar/api/v1/pattern' AND http_method = 'POST';
