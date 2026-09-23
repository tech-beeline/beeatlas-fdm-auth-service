-- V0049 — ALLOW-политика для пользовательских маршрутов staging-service.
--
-- V0046..V0048 добавляли политику только тогда, когда у маршрута не было НИ ОДНОЙ политики
-- (NOT EXISTS по route_id). Если маршрут на стенде уже существовал — например, заведён руками
-- или более ранней правкой, — вставка пропускалась, маршрут оставался под ADMINISTRATOR-политикой
-- вайлдкарда /staging-service/** (V0032), и обычный пользователь получал 403.
--
-- Здесь идемпотентность по самой политике: добавляем ALLOW без роли, если такой ещё нет.

INSERT INTO user_auth.route (path_mask, http_method)
SELECT t.path_mask, t.http_method
FROM (VALUES
    ('/staging-service/api/v1/user/pipeline-runs',              'GET'),
    ('/staging-service/api/v1/pipeline-runs',                   'POST'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/status',    'GET'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/details',   'GET'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/decisions', 'POST'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/apply',     'POST'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/cancel',    'POST'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/decline',   'POST'),
    ('/staging-service/api/v1/search/notices/{runId}',          'GET')
) AS t(path_mask, http_method)
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route r
    WHERE r.path_mask = t.path_mask AND r.http_method = t.http_method
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route r
JOIN (VALUES
    ('/staging-service/api/v1/user/pipeline-runs',              'GET'),
    ('/staging-service/api/v1/pipeline-runs',                   'POST'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/status',    'GET'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/details',   'GET'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/decisions', 'POST'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/apply',     'POST'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/cancel',    'POST'),
    ('/staging-service/api/v1/pipeline-runs/{runId}/decline',   'POST'),
    ('/staging-service/api/v1/search/notices/{runId}',          'GET')
) AS t(path_mask, http_method)
  ON t.path_mask = r.path_mask AND t.http_method = r.http_method
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.policy p
    WHERE p.route_id = r.id
      AND p.role_alias IS NULL
      AND p.permission_alias IS NULL
      AND p.effect = 'ALLOW'
);
