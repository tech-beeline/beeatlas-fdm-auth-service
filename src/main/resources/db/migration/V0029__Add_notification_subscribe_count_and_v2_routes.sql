-- SFDM-3988: метод подсчёта подписок (v1) и метод получения подписок с пагинацией (v2) в fdm-notifications-management

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/api-gateway/notify/v1/subscribe/count', 'GET'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/api-gateway/notify/v1/subscribe/count' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/api-gateway/notify/v1/subscribe/count' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);

INSERT INTO user_auth.route (path_mask, http_method)
SELECT '/notification/api/v2/subscribe', 'GET'
WHERE NOT EXISTS (
    SELECT 1 FROM user_auth.route
    WHERE path_mask = '/notification/api/v2/subscribe' AND http_method = 'GET'
);

INSERT INTO user_auth.policy (route_id, role_alias, permission_alias, effect, priority, check_group_id)
SELECT id, NULL, NULL, 'ALLOW', 0, NULL
FROM user_auth.route
WHERE path_mask = '/notification/api/v2/subscribe' AND http_method = 'GET'
  AND NOT EXISTS (
    SELECT 1 FROM user_auth.policy p2
    WHERE p2.route_id = user_auth.route.id
);
