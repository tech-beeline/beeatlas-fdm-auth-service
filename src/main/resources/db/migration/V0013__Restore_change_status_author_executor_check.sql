-- ════════════════════════════════════════════════════════════════════
-- Восстановить проверку автора/исполнителя для PATCH change-status.
-- V0012 (SFDM-T563) открыл эндпоинт для любого аутентифицированного
-- пользователя. Исходная бизнес-логика: только authorId или executorId
-- заявки могут изменить её статус.
-- check_group 10 (APPLICATION_AUTHOR_OR_EXECUTOR) и FdmBpmClient есть с V0010.
-- ════════════════════════════════════════════════════════════════════

DELETE FROM user_auth.policy
WHERE route_id = (
    SELECT id FROM user_auth.route
    WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}/change-status/{status_alias}'
      AND http_method = 'PATCH'
)
  AND role_alias       IS NULL
  AND permission_alias IS NULL
  AND check_group_id   IS NULL
  AND effect           = 'ALLOW';

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, 10
FROM user_auth.route
WHERE path_mask = '/api-gateway/camunda-process/v1/application/{business_key}/change-status/{status_alias}'
  AND http_method = 'PATCH';

-- ════════════════════════════════════════════════════════════════════
-- Закрыть write-операции techradar через technoradar2 (/techradar/**).
-- V0010 зарегистрировал ADMINISTRATOR-only политики только под префиксом
-- /api-gateway/techradar/v1/. Запросы через technoradar2 идут с префиксом
-- /techradar/ → fdm-auth видит /techradar/api/v1/..., конкретных маршрутов
-- нет → wildcard /techradar/** даёт ALLOW любому аутентифицированному.
-- V0012 закрыл только POST /techradar/api/v1/pattern — PATCH/DELETE пропущены.
-- ════════════════════════════════════════════════════════════════════

INSERT INTO user_auth.route (path_mask, http_method) VALUES
    ('/techradar/api/v1/pattern/{id}',       'PATCH'),
    ('/techradar/api/v1/pattern/{id}',       'DELETE'),
    ('/techradar/api/v1/pattern/group',      'POST'),
    ('/techradar/api/v1/pattern/group/{id}', 'PATCH'),
    ('/techradar/api/v1/pattern/group/{id}', 'DELETE');

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/techradar/api/v1/pattern/{id}'       AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/techradar/api/v1/pattern/{id}'       AND http_method = 'DELETE';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/techradar/api/v1/pattern/group'      AND http_method = 'POST';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/techradar/api/v1/pattern/group/{id}' AND http_method = 'PATCH';
INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM user_auth.route WHERE path_mask = '/techradar/api/v1/pattern/group/{id}' AND http_method = 'DELETE';
