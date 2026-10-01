INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/staging-service/api/v1/pipeline-runs/{runId}/usecase-mappings', 'POST'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/staging-service/api/v1/pipeline-runs/{runId}/usecase-mappings' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route r
WHERE r.path_mask = '/staging-service/api/v1/pipeline-runs/{runId}/usecase-mappings' AND r.http_method = 'POST'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p
    WHERE p.route_id = r.id
      AND p.role_alias IS NULL
      AND p.permission_alias IS NULL
      AND p.effect = 'ALLOW'
);
