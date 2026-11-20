DELETE FROM user_auth.policy
WHERE route_id IN (
    SELECT id FROM user_auth.route
    WHERE path_mask IN (
            '/cx/api/cx/v1/bpmn/cj',
            '/api-gateway/cx/v1/bpmn/cj'
        )
      AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, NULL, 'EDIT_ARTIFACT', 'ALLOW', 0, NULL
FROM user_auth.route r
WHERE r.path_mask IN (
        '/cx/api/cx/v1/bpmn/cj',
        '/api-gateway/cx/v1/bpmn/cj'
    )
  AND r.http_method = 'POST'
  AND NOT EXISTS (
      SELECT 1 FROM user_auth.policy p
      WHERE p.route_id = r.id
        AND p.role_alias IS NULL
        AND p.permission_alias = 'EDIT_ARTIFACT'
        AND p.effect = 'ALLOW'
  );
