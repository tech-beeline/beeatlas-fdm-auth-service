DELETE FROM user_auth.policy
WHERE route_id IN (
    SELECT id FROM user_auth.route
    WHERE path_mask IN (
            '/cx/api/cx/v1/cj/{id}',
            '/api-gateway/cx/v1/cj/{id}'
        )
      AND http_method = 'PATCH'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route r
WHERE r.path_mask IN (
        '/cx/api/cx/v1/cj/{id}',
        '/api-gateway/cx/v1/cj/{id}'
    )
  AND r.http_method = 'PATCH'
  AND NOT EXISTS (
      SELECT 1 FROM user_auth.policy p
      WHERE p.route_id = r.id
        AND p.role_alias IS NULL
        AND p.permission_alias IS NULL
        AND p.effect = 'ALLOW'
  );
