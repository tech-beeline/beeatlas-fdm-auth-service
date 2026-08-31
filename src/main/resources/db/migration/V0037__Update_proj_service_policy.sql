UPDATE user_auth.policy
SET role_alias = NULL
WHERE route_id = (
    SELECT id
    FROM user_auth.route
    WHERE path_mask = '/project/api/v1/project'
      AND http_method = 'POST'
);