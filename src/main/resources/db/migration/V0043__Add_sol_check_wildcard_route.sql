-- V0043 — wildcard-маршрут /solution-checker/** для solution-checker-backend.
--
-- V0038 завела 16 точечных маршрутов (/solution-checker/api/intake/..., /api/bc/..., /api/tc/...,
-- /api/publish/...). Любой новый метод бэкенда, не перечисленный там, попадает в ветку
-- matchedRoutes.isEmpty() в AuthorizationService.authorize() и получает
-- DENY "Route not registered" -> gateway отвечает 403. Чтобы новые методы появлялись на GW
-- автоматически, без миграции на каждую ручку, регистрируем одну wildcard-маску.
--
-- http_method = NULL означает «любой метод» (см. фильтр по r.getHttpMethod() == null
-- в AuthorizationService). AntPathMatcher + pathMatcher.getPatternComparator(path) отдают
-- приоритет более специфичной маске, поэтому точечные маршруты V0038 продолжают выигрывать
-- у /**, а wildcard срабатывает только как fallback — тот же приём, что в V0011 и V0032.
--
-- ValidateTokenFilter авторизует запрос ДО RewritePath на гейтвее, поэтому маска описывает
-- pre-rewrite путь (/solution-checker/**), а не внутренний путь бэкенда (/api/**) —
-- см. комментарии в V0016/V0023/V0032.
--
-- Политика — «любой аутентифицированный пользователь» (role_alias/permission_alias = NULL),
-- как у всех 16 политик solution-checker из V0038.

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/solution-checker/**', NULL
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/solution-checker/**' AND http_method IS NULL
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/solution-checker/**' AND http_method IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );
