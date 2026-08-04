-- ════════════════════════════════════════════════════════════════════
--  CJ больше не привязан к продукту в модели доступа.
--  Группы проверок 1 (CjStepProductGroup), 6 (CjProductGroup),
--  7 (CjCreateProductGroup), 8 (CjEditProductGroup) используются только
--  для CJ (не переиспользуются для BI — у BI свои группы 2-5) и
--  встречаются в политиках, добавленных несколькими независимыми
--  миграциями (V0010, V0011, V0012, V0016) для разных генераций
--  gateway-путей. Обнуляем их разом по check_group_id, не привязываясь
--  к конкретному роуту/миграции.
-- ════════════════════════════════════════════════════════════════════

UPDATE user_auth.policy
SET check_group_id = NULL
WHERE check_group_id IN (1, 6, 7, 8);

-- ── CJ creation: productId переезжает из пути в тело запроса ─────────
-- Регистрируем новый роут (обе генерации gateway-путей), переносим на
-- него политики CREATE_ARTIFACT / DESIGN_ARTIFACT, и убираем старый
-- роут с productId в пути.

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/api-gateway/cx/v1/product/cj', 'POST'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/api-gateway/cx/v1/product/cj' AND http_method = 'POST'
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/cx/api/cx/v1/product/cj', 'POST'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/cx/api/cx/v1/product/cj' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj' AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'CREATE_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/api-gateway/cx/v1/product/cj' AND http_method = 'POST';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'DESIGN_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj' AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, 'CREATE_ARTIFACT', 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/cx/api/cx/v1/product/cj' AND http_method = 'POST';

DELETE FROM user_auth.policy
WHERE route_id IN (
    SELECT id FROM user_auth.route
    WHERE path_mask IN ('/api-gateway/cx/v1/product/{productId}/cj', '/cx/api/cx/v1/product/{productId}/cj')
      AND http_method = 'POST'
);

DELETE FROM user_auth.route
WHERE path_mask IN ('/api-gateway/cx/v1/product/{productId}/cj', '/cx/api/cx/v1/product/{productId}/cj')
  AND http_method = 'POST';

-- ── Чистка осиротевших check_group ─────────────────────────────────────
-- Группы 1/6/7/8 (по одной строке на group_id, все в V0010) больше ничем
-- не используются — удаляем.
DELETE FROM user_auth.check_group WHERE group_id IN (1, 6, 7, 8);

-- check_type: CJ_PRODUCT_MEMBER/CJ_STEP_PRODUCT_MEMBER/CJ_EDIT_PRODUCT_MEMBER
-- использовались исключительно группами 6/1/8 — удаляем.
-- PRODUCT_MEMBER_FROM_PATH НЕ удаляем: помимо группы 7 (CJ-создание) этот
-- же check_type переиспользует group_id=12 'ProductMemberByIdGroup'
-- (product-service, /product/api/v1/product/{id}/structurizr-key) —
-- удаление типа сломало бы FK check_group_check_type_id_fkey для группы 12.
DELETE FROM user_auth.check_type
WHERE name IN ('CJ_PRODUCT_MEMBER', 'CJ_STEP_PRODUCT_MEMBER', 'CJ_EDIT_PRODUCT_MEMBER');
