-- V0042 — регистрация PUT /project/api/v1/project/{projectId}/use-case
-- (ProjectUseCaseController в project-backend). Маршрут не был заведён ни в V0035, ни в V0036:
-- AuthorizationService.authorize() отдаёт DENY по умолчанию для любого несопоставленного
-- (path, method) — см. AuthorizationService.java, ветка matchedRoutes.isEmpty() — то есть через
-- реальный gateway метод отвечал бы 403.
--
-- Политика — «любой аутентифицированный пользователь», как у GET/POST /project/api/v1/project
-- (V0035, V0037): отдельной роли «владелец use case» нет, publish выполняет ProjectTask.

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/project/api/v1/project/{projectId}/use-case', 'PUT'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/project/api/v1/project/{projectId}/use-case' AND http_method = 'PUT'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/project/api/v1/project/{projectId}/use-case' AND http_method = 'PUT'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );
