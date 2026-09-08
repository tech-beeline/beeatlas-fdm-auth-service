-- V0041 — SFDM-4080: регистрация PUT /product/api/v1/product/{alias}/sequence
-- (ProductSequenceController в fdm-products). Без записи в route + policy
-- AuthorizationService.authorize() отдаёт DENY по умолчанию для любого несопоставленного
-- (path, method) — см. AuthorizationService.java, ветка matchedRoutes.isEmpty() — то есть через
-- реальный gateway метод отвечал бы 403.
--
-- Политика — «любой аутентифицированный пользователь», как у POST /product/api/v1/e2e (V0025):
-- публикацию выполняет staging / publisher, отдельной роли «владелец sequence» пока нет.

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/product/api/v1/product/{alias}/sequence', 'PUT'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/product/api/v1/product/{alias}/sequence' AND http_method = 'PUT'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 10, NULL
FROM user_auth.route
WHERE path_mask = '/product/api/v1/product/{alias}/sequence' AND http_method = 'PUT'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );
