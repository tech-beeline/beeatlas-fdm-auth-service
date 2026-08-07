/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.service.rbac;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.AntPathMatcher;
import ru.beeline.fdmauth.domain.rbac.CheckGroup;
import ru.beeline.fdmauth.domain.rbac.Policy;
import ru.beeline.fdmauth.domain.rbac.Route;
import ru.beeline.fdmauth.dto.PermissionTypeDTO;
import ru.beeline.fdmauth.dto.UserInfoDTO;
import ru.beeline.fdmauth.dto.rbac.AuthorizeRequestDTO;
import ru.beeline.fdmauth.dto.rbac.AuthorizeResponseDTO;
import ru.beeline.fdmauth.repository.rbac.CheckGroupRepository;
import ru.beeline.fdmauth.repository.rbac.PolicyRepository;
import ru.beeline.fdmauth.repository.rbac.RouteRepository;
import ru.beeline.fdmauth.service.UserProfileService;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Slf4j
public class AuthorizationService {

    @Autowired
    private RouteRepository routeRepository;

    @Autowired
    private PolicyRepository policyRepository;

    @Autowired
    private CheckGroupRepository checkGroupRepository;

    @Autowired
    private CheckStrategyExecutor checkStrategyExecutor;

    @Autowired
    private UserProfileService userProfileService;

    @Autowired
    private RbacAuditService rbacAuditService;

    private final AntPathMatcher pathMatcher = new AntPathMatcher();

    private volatile List<Route> routeCache = null;
    private volatile Map<Long, List<Policy>> policyByRouteIdCache = null;
    private final Object cacheLock = new Object();

    public void invalidateRouteCache() {
        routeCache = null;
        policyByRouteIdCache = null;
    }

    private List<Route> getRoutes() {
        ensureCacheLoaded();
        return routeCache;
    }

    private Map<Long, List<Policy>> getPoliciesByRouteId() {
        ensureCacheLoaded();
        return policyByRouteIdCache;
    }

    private void ensureCacheLoaded() {
        if (routeCache == null || policyByRouteIdCache == null) {
            synchronized (cacheLock) {
                if (routeCache == null || policyByRouteIdCache == null) {
                    routeCache = routeRepository.findAll();
                    Map<Long, List<Policy>> map = new HashMap<>();
                    policyRepository.findAllWithRoute().forEach(p ->
                            map.computeIfAbsent(p.getRoute().getId(), k -> new ArrayList<>()).add(p));
                    policyByRouteIdCache = map;
                }
            }
        }
    }

    public AuthorizeResponseDTO authorize(AuthorizeRequestDTO request) {
        List<String> roles = request.getRoles() != null ? request.getRoles() : Collections.emptyList();
        List<String> permissions = request.getPermissions() != null ? request.getPermissions() : Collections.emptyList();

        Integer userId = request.getUserId();
        List<Long> productIds = request.getProductIds() != null ? request.getProductIds() : Collections.emptyList();

        if (userId == null) {
            String login = request.getEmail() != null
                    ? request.getEmail().substring(0, request.getEmail().indexOf("@")) : null;
            UserInfoDTO userInfo = userProfileService.getUserInfo(
                    login, request.getEmail(), request.getFullName(), request.getIdExt());
            roles = userInfo.getRoles() != null ? userInfo.getRoles() : Collections.emptyList();
            permissions = userInfo.getPermissions() != null
                    ? userInfo.getPermissions().stream().map(PermissionTypeDTO::name).collect(Collectors.toList())
                    : Collections.emptyList();
            userId = userInfo.getId();
            productIds = userInfo.getProductsIds() != null ? userInfo.getProductsIds() : Collections.emptyList();
        }

        final List<String> finalRoles = roles;
        final List<String> finalPermissions = permissions;
        final Integer finalUserId = userId;
        final List<Long> finalProductIds = productIds;
        final String method = request.getMethod();
        final String path = request.getPath();

        List<Route> allRoutes = getRoutes();
        List<Route> matchedRoutes = allRoutes.stream()
                .filter(r -> r.getHttpMethod() == null || r.getHttpMethod().equalsIgnoreCase(method))
                .filter(r -> pathMatcher.match(r.getPathMask(), path))
                .collect(Collectors.toList());

        if (matchedRoutes.size() > 1) {
            Comparator<String> specificity = pathMatcher.getPatternComparator(path);
            String mostSpecific = matchedRoutes.stream()
                    .map(Route::getPathMask)
                    .min(specificity)
                    .orElse(null);
            if (mostSpecific != null) {
                matchedRoutes = matchedRoutes.stream()
                        .filter(r -> specificity.compare(r.getPathMask(), mostSpecific) == 0)
                        .collect(Collectors.toList());
            }
        }

        if (matchedRoutes.isEmpty()) {
            String desc = "roles=" + finalRoles + "; no-route";
            rbacAuditService.record(finalUserId, method, path, "DENY", desc, "{}");
            return response("DENY", finalUserId, finalRoles, finalPermissions, finalProductIds,
                    "Route not registered: " + method + " " + path);
        }

        String matchedMasks = matchedRoutes.stream().map(Route::getPathMask).collect(Collectors.joining(","));
        List<Long> routeIds = matchedRoutes.stream().map(Route::getId).collect(Collectors.toList());

        Map<Long, List<Policy>> policyCache = getPoliciesByRouteId();
        List<Policy> allPolicies = routeIds.stream()
                .flatMap(id -> policyCache.getOrDefault(id, Collections.emptyList()).stream())
                .collect(Collectors.toList());

        List<Policy> matchingPolicies = allPolicies.stream()
                .filter(p -> p.getRoleAlias() == null || finalRoles.contains(p.getRoleAlias()))
                .filter(p -> p.getPermissionAlias() == null || finalPermissions.contains(p.getPermissionAlias()))
                .collect(Collectors.toList());

        Map<String, String> pathVars = extractPathVars(matchedRoutes, path);
        Map<String, String> queryParams = request.getQueryParams() != null
                ? request.getQueryParams() : Collections.emptyMap();
        String bodyJson = request.getBodyJson();
        String params = buildParams(pathVars, queryParams, bodyJson);

        if (matchingPolicies.isEmpty()) {
            String desc = "roles=" + finalRoles + "; route=" + matchedMasks
                    + "; no-matching-policy(total=" + allPolicies.size() + ")";
            rbacAuditService.record(finalUserId, method, path, "DENY", desc, params);
            return response("DENY", finalUserId, finalRoles, finalPermissions, finalProductIds);
        }

        UserInfoDTO userInfoForChecks = UserInfoDTO.builder()
                .id(finalUserId)
                .roles(finalRoles)
                .productsIds(finalProductIds)
                .permissionNames(finalPermissions)
                .build();

        Map<Integer, List<Policy>> byPriority = matchingPolicies.stream()
                .collect(Collectors.groupingBy(Policy::getPriority));

        List<Integer> priorities = new ArrayList<>(byPriority.keySet());
        priorities.sort(Comparator.reverseOrder());

        List<String> trace = new ArrayList<>();
        trace.add("roles=" + finalRoles);
        trace.add("route=" + matchedMasks);

        for (Integer priority : priorities) {
            List<Policy> group = byPriority.get(priority);
            boolean anyAllowPassed = false;
            boolean anyDenyPassed = false;
            List<String> groupTrace = new ArrayList<>();

            for (Policy policy : group) {
                boolean checkPassed = evaluateCheckGroup(policy, userInfoForChecks, pathVars, queryParams, bodyJson);
                String policyKey = "role=" + policy.getRoleAlias()
                        + "/perm=" + policy.getPermissionAlias()
                        + "/eff=" + policy.getEffect()
                        + "/grp=" + policy.getCheckGroupId();
                groupTrace.add(policyKey + ":" + (checkPassed ? policy.getEffect() : "skip"));
                if (checkPassed) {
                    if ("DENY".equals(policy.getEffect())) anyDenyPassed = true;
                    else anyAllowPassed = true;
                }
            }

            String groupResult = anyAllowPassed ? "ALLOW" : anyDenyPassed ? "DENY" : "skip";
            trace.add("pri=" + priority + "[" + String.join(",", groupTrace) + "]->" + groupResult);

            if (anyAllowPassed) {
                trace.add("FINAL=ALLOW");
                rbacAuditService.record(finalUserId, method, path, "ALLOW", String.join("; ", trace), params);
                return response("ALLOW", finalUserId, finalRoles, finalPermissions, finalProductIds);
            }
            if (anyDenyPassed) {
                trace.add("FINAL=DENY");
                rbacAuditService.record(finalUserId, method, path, "DENY", String.join("; ", trace), params);
                return response("DENY", finalUserId, finalRoles, finalPermissions, finalProductIds);
            }
        }

        trace.add("FINAL=DENY(no-priority-passed)");
        rbacAuditService.record(finalUserId, method, path, "DENY", String.join("; ", trace), params);
        return response("DENY", finalUserId, finalRoles, finalPermissions, finalProductIds);
    }

    private String buildParams(Map<String, String> pathVars, Map<String, String> queryParams, String bodyJson) {
        StringBuilder sb = new StringBuilder("{");
        sb.append("\"pathVars\":").append(mapToJson(pathVars));
        sb.append(",\"queryParams\":").append(mapToJson(queryParams));
        if (bodyJson != null && !bodyJson.isBlank()) {
            String body = bodyJson.length() > 500 ? bodyJson.substring(0, 500) : bodyJson;
            sb.append(",\"body\":").append(body);
        }
        sb.append("}");
        return sb.toString();
    }

    private String mapToJson(Map<String, String> map) {
        if (map == null || map.isEmpty()) return "{}";
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, String> e : map.entrySet()) {
            if (!first) sb.append(",");
            sb.append("\"").append(e.getKey().replace("\"", "\\\""))
              .append("\":\"").append(e.getValue() != null ? e.getValue().replace("\"", "\\\"") : "").append("\"");
            first = false;
        }
        sb.append("}");
        return sb.toString();
    }

    private AuthorizeResponseDTO response(String decision, Integer userId, List<String> roles,
                                          List<String> permissions, List<Long> productIds) {
        return response(decision, userId, roles, permissions, productIds, null);
    }

    private AuthorizeResponseDTO response(String decision, Integer userId, List<String> roles,
                                          List<String> permissions, List<Long> productIds, String message) {
        return AuthorizeResponseDTO.builder()
                .decision(decision)
                .userId(userId)
                .productIds(productIds)
                .roles(roles)
                .permissions(permissions)
                .message(message)
                .build();
    }

    private boolean evaluateCheckGroup(Policy policy, UserInfoDTO userInfo,
                                       Map<String, String> pathVars, Map<String, String> queryParams,
                                       String bodyJson) {
        if (policy.getCheckGroupId() == null) {
            return true;
        }

        List<CheckGroup> checks = checkGroupRepository.findByGroupId(policy.getCheckGroupId());
        if (checks.isEmpty()) {
            return true;
        }

        for (CheckGroup check : checks) {
            if (!checkStrategyExecutor.execute(check, userInfo, pathVars, queryParams, bodyJson)) {
                return false;
            }
        }
        return true;
    }

    private Map<String, String> extractPathVars(List<Route> matchedRoutes, String path) {
        for (Route route : matchedRoutes) {
            if (pathMatcher.match(route.getPathMask(), path)) {
                try {
                    return pathMatcher.extractUriTemplateVariables(route.getPathMask(), path);
                } catch (Exception e) {
                    log.warn("Failed to extract path vars from mask={} path={}: {}", route.getPathMask(), path, e.getMessage());
                }
            }
        }
        return Collections.emptyMap();
    }
}
