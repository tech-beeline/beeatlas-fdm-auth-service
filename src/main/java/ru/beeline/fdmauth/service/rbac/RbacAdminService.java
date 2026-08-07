/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.service.rbac;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.beeline.fdmauth.domain.rbac.CheckGroup;
import ru.beeline.fdmauth.domain.rbac.CheckType;
import ru.beeline.fdmauth.domain.rbac.Policy;
import ru.beeline.fdmauth.domain.rbac.Route;
import ru.beeline.fdmauth.dto.rbac.PolicyConflictDTO;
import ru.beeline.fdmauth.dto.rbac.PolicyFullDTO;
import ru.beeline.fdmauth.dto.rbac.RouteRegistrationDTO;
import ru.beeline.fdmauth.exception.EntityNotFoundException;
import ru.beeline.fdmauth.repository.rbac.CheckGroupRepository;
import ru.beeline.fdmauth.repository.rbac.CheckTypeRepository;
import ru.beeline.fdmauth.repository.rbac.PolicyRepository;
import ru.beeline.fdmauth.repository.rbac.RouteRepository;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class RbacAdminService {

    @Autowired
    private RouteRepository routeRepository;

    @Autowired
    private CheckTypeRepository checkTypeRepository;

    @Autowired
    private CheckGroupRepository checkGroupRepository;

    @Autowired
    private PolicyRepository policyRepository;

    @Autowired
    private AuthorizationService authorizationService;

    public List<PolicyFullDTO> getAllPolicies() {
        return policyRepository.findAll().stream()
                .map(this::toFullDTO)
                .collect(Collectors.toList());
    }

    public PolicyFullDTO getPolicy(Long id) {
        return toFullDTO(findPolicy(id));
    }

    @Transactional(transactionManager = "transactionManager")
    public PolicyFullDTO createPolicy(PolicyFullDTO dto) {
        Route route = findOrCreateRoute(dto.getPathMask(), dto.getHttpMethod());
        Integer checkGroupId = saveCheckGroup(null, dto.getCheckTypeNames());
        Policy policy = policyRepository.save(Policy.builder()
                .route(route)
                .roleAlias(dto.getRoleAlias())
                .permissionAlias(dto.getPermissionAlias())
                .effect(dto.getEffect())
                .priority(dto.getPriority())
                .checkGroupId(checkGroupId)
                .build());
        authorizationService.invalidateRouteCache();
        return toFullDTO(policy);
    }

    @Transactional(transactionManager = "transactionManager")
    public PolicyFullDTO updatePolicy(Long id, PolicyFullDTO dto) {
        Policy policy = findPolicy(id);
        policy.setRoute(findOrCreateRoute(dto.getPathMask(), dto.getHttpMethod()));
        policy.setRoleAlias(dto.getRoleAlias());
        policy.setPermissionAlias(dto.getPermissionAlias());
        policy.setEffect(dto.getEffect());
        policy.setPriority(dto.getPriority());
        policy.setCheckGroupId(saveCheckGroup(policy.getCheckGroupId(), dto.getCheckTypeNames()));
        authorizationService.invalidateRouteCache();
        return toFullDTO(policyRepository.save(policy));
    }

    @Transactional(transactionManager = "transactionManager")
    public void deletePolicy(Long id) {
        Policy policy = findPolicy(id);
        if (policy.getCheckGroupId() != null) {
            checkGroupRepository.deleteByGroupId(policy.getCheckGroupId());
        }
        policyRepository.deleteById(id);
        authorizationService.invalidateRouteCache();
    }

    public List<CheckType> getAllCheckTypes() {
        return checkTypeRepository.findAll();
    }

    @Transactional(transactionManager = "transactionManager")
    public void registerRoutes(List<RouteRegistrationDTO> routes) {
        for (RouteRegistrationDTO dto : routes) {
            if (dto.getPath() == null || dto.getPath().isBlank()) continue;
            Optional<Route> existing = routeRepository.findByPathMaskAndHttpMethod(dto.getPath(), dto.getMethod());
            if (existing.isPresent()) continue;
            Route route = routeRepository.save(Route.builder()
                    .pathMask(dto.getPath())
                    .httpMethod(dto.getMethod())
                    .build());
            policyRepository.save(Policy.builder()
                    .route(route)
                    .roleAlias(null)
                    .permissionAlias(null)
                    .effect("ALLOW")
                    .priority(0)
                    .checkGroupId(null)
                    .build());
        }
        authorizationService.invalidateRouteCache();
    }

    public List<PolicyFullDTO> exportPolicies() {
        return getAllPolicies();
    }

    @Transactional(transactionManager = "transactionManager")
    public List<PolicyConflictDTO> importPolicies(List<PolicyFullDTO> policies, boolean reWrite) {
        List<PolicyConflictDTO> conflicts = new ArrayList<>();
        for (PolicyFullDTO incoming : policies) {
            Route route = findOrCreateRoute(incoming.getPathMask(), incoming.getHttpMethod());
            Optional<Policy> existingOpt = policyRepository.findConflicting(
                    route, incoming.getRoleAlias(), incoming.getPermissionAlias(), incoming.getEffect());
            if (existingOpt.isPresent()) {
                Policy existing = existingOpt.get();
                PolicyFullDTO existingDTO = toFullDTO(existing);
                boolean exactMatch = Objects.equals(existingDTO.getPriority(), incoming.getPriority())
                        && Objects.equals(new java.util.HashSet<>(existingDTO.getCheckTypeNames()),
                                          new java.util.HashSet<>(incoming.getCheckTypeNames()));
                if (!exactMatch) {
                    if (reWrite) {
                        existing.setPriority(incoming.getPriority());
                        existing.setCheckGroupId(saveCheckGroup(existing.getCheckGroupId(), incoming.getCheckTypeNames()));
                        policyRepository.save(existing);
                    } else {
                        conflicts.add(new PolicyConflictDTO(existingDTO, incoming));
                    }
                }
            } else {
                policyRepository.save(Policy.builder()
                        .route(route)
                        .roleAlias(incoming.getRoleAlias())
                        .permissionAlias(incoming.getPermissionAlias())
                        .effect(incoming.getEffect())
                        .priority(incoming.getPriority())
                        .checkGroupId(saveCheckGroup(null, incoming.getCheckTypeNames()))
                        .build());
            }
        }
        authorizationService.invalidateRouteCache();
        return conflicts;
    }

    private Policy findPolicy(Long id) {
        return policyRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Policy not found: " + id));
    }

    private Route findOrCreateRoute(String pathMask, String httpMethod) {
        return routeRepository.findByPathMaskAndHttpMethod(pathMask, httpMethod)
                .orElseGet(() -> routeRepository.save(Route.builder()
                        .pathMask(pathMask)
                        .httpMethod(httpMethod)
                        .build()));
    }

    private Integer saveCheckGroup(Integer existingGroupId, List<String> checkTypeNames) {
        if (existingGroupId != null) {
            checkGroupRepository.deleteByGroupId(existingGroupId);
        }
        if (checkTypeNames == null || checkTypeNames.isEmpty()) {
            return null;
        }
        int groupId = checkGroupRepository.findMaxGroupId() + 1;
        for (String checkTypeName : checkTypeNames) {
            CheckType checkType = checkTypeRepository.findAll().stream()
                    .filter(ct -> ct.getName().equals(checkTypeName))
                    .findFirst()
                    .orElseThrow(() -> new EntityNotFoundException("CheckType not found: " + checkTypeName));
            checkGroupRepository.save(CheckGroup.builder()
                    .groupId(groupId)
                    .checkType(checkType)
                    .build());
        }
        return groupId;
    }

    private PolicyFullDTO toFullDTO(Policy policy) {
        List<String> checkTypeNames = policy.getCheckGroupId() != null
                ? checkGroupRepository.findByGroupId(policy.getCheckGroupId()).stream()
                        .map(cg -> cg.getCheckType().getName())
                        .collect(Collectors.toList())
                : Collections.emptyList();

        return PolicyFullDTO.builder()
                .id(policy.getId())
                .pathMask(policy.getRoute().getPathMask())
                .httpMethod(policy.getRoute().getHttpMethod())
                .roleAlias(policy.getRoleAlias())
                .permissionAlias(policy.getPermissionAlias())
                .effect(policy.getEffect())
                .priority(policy.getPriority())
                .checkTypeNames(checkTypeNames)
                .build();
    }
}
