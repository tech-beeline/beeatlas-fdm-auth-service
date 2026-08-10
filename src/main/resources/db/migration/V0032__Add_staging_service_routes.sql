-- V0032 — Register staging-service behind the fdm-gateway "/staging-service" prefix (route
-- "stagingservice", path.stagingservice=/staging-service, RewritePath=/staging-service/(?<segment>.*)
-- -> /$segment).
--
-- staging-service is a pure internal ops/pipeline-admin surface (scan triggers, retry endpoints,
-- notice-type triage, raw pipeline data inspection) — no end-user-facing data. ADMINISTRATOR-only,
-- one wildcard route covering all four controllers (AdminController, PipelineRunsController,
-- RawDataController, ConfigurationController).
--
-- ValidateTokenFilter authorizes requests BEFORE the gateway rewrites the path, so fdm-auth must
-- match on the pre-rewrite gateway path (/staging-service/**), not the backend-internal path
-- (/admin/**, /api/v1/pipeline-runs/**, ...) — see V0016/V0023 for the same gotcha elsewhere.

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/staging-service/**', NULL
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/staging-service/**' AND http_method IS NULL
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/staging-service/**' AND http_method IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
  );
