CREATE TEMP TABLE tmp_closed_manual_cj_bi (
    path_mask   text NOT NULL,
    http_method text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_closed_manual_cj_bi (path_mask, http_method) VALUES
    ('/cx/api/cx/v1/product/cj', 'POST'),
    ('/api-gateway/cx/v1/product/cj', 'POST'),
    ('/cx/api/cx/v1/product/cj/{id}', 'PUT'),
    ('/api-gateway/cx/v1/product/cj/{id}', 'PUT'),
    ('/cx/api/cx/v1/product/cj/{id}', 'PATCH'),
    ('/api-gateway/cx/v1/product/cj/{id}', 'PATCH'),
    ('/cx/api/cx/v1/product/cj/{id}/step', 'POST'),
    ('/api-gateway/cx/v1/product/cj/{id}/step', 'POST'),
    ('/cx/api/cx/v1/product/cj/step/{id}', 'PATCH'),
    ('/api-gateway/cx/v1/product/cj/step/{id}', 'PATCH'),
    ('/cx/api/cx/v1/product/cj/step/{id}', 'DELETE'),
    ('/api-gateway/cx/v1/product/cj/step/{id}', 'DELETE'),
    ('/cx/api/cx/v1/product/cj/step/{id}/bi', 'PUT'),
    ('/api-gateway/cx/v1/product/cj/step/{id}/bi', 'PUT'),
    ('/cx/api/cx/v1/product/cj/step/{id_step}/bi/{id}', 'DELETE'),
    ('/api-gateway/cx/v1/product/cj/step/{id_step}/bi/{id}', 'DELETE'),
    ('/cx/api/cx/v1/library/business-interactions', 'POST'),
    ('/api-gateway/cx/v1/library/business-interactions', 'POST');

DELETE FROM user_auth.policy
WHERE route_id IN (
    SELECT r.id
    FROM user_auth.route r
    JOIN tmp_closed_manual_cj_bi t
      ON t.path_mask = r.path_mask
     AND t.http_method = r.http_method
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT r.id, roles.role_alias, NULL, 'ALLOW', 0, NULL
FROM user_auth.route r
JOIN tmp_closed_manual_cj_bi t
  ON t.path_mask = r.path_mask
 AND t.http_method = r.http_method
CROSS JOIN (VALUES ('CX_SPECIALIST'), ('CX_ADMINISTRATOR'), ('ADMINISTRATOR')) AS roles(role_alias)
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.policy p
    WHERE p.route_id = r.id
      AND p.role_alias = roles.role_alias
      AND p.permission_alias IS NULL
      AND p.effect = 'ALLOW'
);
