INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/cx/api/cx/v1/bpmn/cj', 'POST'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/cx/api/cx/v1/bpmn/cj' AND http_method = 'POST'
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/api-gateway/cx/v1/bpmn/cj', 'POST'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/api-gateway/cx/v1/bpmn/cj' AND http_method = 'POST'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route r
WHERE r.path_mask IN ('/cx/api/cx/v1/bpmn/cj', '/api-gateway/cx/v1/bpmn/cj')
  AND r.http_method = 'POST'
  AND NOT EXISTS (
      SELECT 1 FROM user_auth.policy p
      WHERE p.route_id = r.id
        AND p.role_alias IS NULL
        AND p.permission_alias IS NULL
        AND p.effect = 'ALLOW'
  );

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/cx/api/cx/v1/cj/{id}/attributes', 'PATCH'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/cx/api/cx/v1/cj/{id}/attributes' AND http_method = 'PATCH'
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/api-gateway/cx/v1/cj/{id}/attributes', 'PATCH'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/api-gateway/cx/v1/cj/{id}/attributes' AND http_method = 'PATCH'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route r
WHERE r.path_mask IN ('/cx/api/cx/v1/cj/{id}/attributes', '/api-gateway/cx/v1/cj/{id}/attributes')
  AND r.http_method = 'PATCH'
  AND NOT EXISTS (
      SELECT 1 FROM user_auth.policy p
      WHERE p.route_id = r.id
        AND p.role_alias IS NULL
        AND p.permission_alias IS NULL
        AND p.effect = 'ALLOW'
  );
