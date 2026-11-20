DELETE FROM user_auth.policy
WHERE route_id IN (
    SELECT id FROM user_auth.route
    WHERE (path_mask = '/cx/api/cx/v1/cj/{id}' AND http_method IN ('PUT', 'PATCH'))
       OR (path_mask = '/api-gateway/cx/v1/cj/{id}' AND http_method IN ('PUT', 'PATCH'))
       OR (path_mask = '/cx/api/cx/v1/cj/{id}/step' AND http_method = 'POST')
       OR (path_mask = '/api-gateway/cx/v1/cj/{id}/step' AND http_method = 'POST')
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, roles.role_alias, NULL, 'ALLOW', 0, NULL
FROM user_auth.route r
         CROSS JOIN (VALUES ('CX_SPECIALIST'), ('CX_ADMINISTRATOR'), ('ADMINISTRATOR')) AS roles(role_alias)
WHERE (
    (r.path_mask = '/cx/api/cx/v1/cj/{id}' AND r.http_method IN ('PUT', 'PATCH'))
        OR (r.path_mask = '/api-gateway/cx/v1/cj/{id}' AND r.http_method IN ('PUT', 'PATCH'))
        OR (r.path_mask = '/cx/api/cx/v1/cj/{id}/step' AND r.http_method = 'POST')
        OR (r.path_mask = '/api-gateway/cx/v1/cj/{id}/step' AND r.http_method = 'POST')
    )
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p
    WHERE p.route_id = r.id
      AND p.role_alias = roles.role_alias
      AND p.permission_alias IS NULL
      AND p.effect = 'ALLOW'
);
