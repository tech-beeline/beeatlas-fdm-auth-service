-- V0023 — Fix path_mask for the project service routes.
--
-- V0010 seeded the project routes using the legacy /api-gateway/<service>/v1/...
-- convention:
--   /api-gateway/project/v1/project                            POST
--   /api-gateway/project/v1/project/{projectId}/user/{userId}  POST
--
-- The actual gateway route for the project service (fdm-gateway "projectService",
-- SFDM-3812) only uses the flat-prefix convention: path.project=/project, with
-- RewritePath=/project/(?<segment>.*) -> /$segment. There is no /api-gateway/project/...
-- route configured on the gateway at all.
--
-- ValidateTokenFilter authorizes requests BEFORE the gateway rewrites the path, so
-- fdm-auth receives the pre-rewrite gateway path. Real requests therefore arrive as
--   /project/api/v1/project
--   /project/api/v1/project/{projectId}/user/{userId}
-- which never matched the seeded masks. With no matching route, authorize() returns
-- DENY ("Route not registered") before any policy (including the ADMINISTRATOR
-- ALLOW rows) is even evaluated — so every caller, including ADMINISTRATOR, got 403.
--
-- This updates the existing route rows in place so the ADMINISTRATOR-only policies
-- already attached to them (via route_id) keep applying without changes.

UPDATE user_auth.route
SET path_mask = '/project/api/v1/project'
WHERE path_mask = '/api-gateway/project/v1/project' AND http_method = 'POST';

UPDATE user_auth.route
SET path_mask = '/project/api/v1/project/{projectId}/user/{userId}'
WHERE path_mask = '/api-gateway/project/v1/project/{projectId}/user/{userId}' AND http_method = 'POST';
