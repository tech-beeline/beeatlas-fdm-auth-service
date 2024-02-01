package ru.beeline.fdmauth.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.HttpClientErrorException;
import ru.beeline.fdmauth.domain.*;
import ru.beeline.fdmauth.dto.RoleShortDTO;
import ru.beeline.fdmauth.repository.RolePermissionsRepository;
import ru.beeline.fdmauth.repository.RoleRepository;
import ru.beeline.fdmauth.repository.UserRolesRepository;
import ru.beeline.fdmauth.dto.PermissionDTO;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class RoleService {

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private RolePermissionsRepository rolePermissionsRepository;

    @Autowired
    private UserRolesRepository userRolesRepository;

    @Autowired
    private PermissionService permissionService;

    public List<Role> getAllRoles() {
        return roleRepository.findAll();
    }

    @Transactional(transactionManager = "transactionManager")
    public Role createRole(RoleShortDTO role) {
        Role newRole = Role.builder()
                .name(role.getName())
                .descr(role.getName())
                .alias(Role.RoleType.DEFAULT)
                .deleted(false)
                .build();
        roleRepository.save(newRole);
        return newRole;
    }

    public boolean checkNameIsUnique(String name) {
        Role roleWithName = roleRepository.findRoleByName(name);
        return roleWithName != null;
    }

    @Transactional(transactionManager = "transactionManager")
    public Role updateRole(Long id, RoleShortDTO role) {
        Optional<Role> currentRoleOpt = roleRepository.findById(id);
        if(!currentRoleOpt.isPresent()) throw new HttpClientErrorException(HttpStatus.NOT_FOUND);
        else {
            Role currentRole = currentRoleOpt.get();
            currentRole.setName(role.getName());
            currentRole.setDescr(role.getName());
            roleRepository.save(currentRole);
            return currentRole;
        }
    }

    public Optional<Role> findRole(Long id) {
        return roleRepository.findById(id);
    }

    public Role findRoleByName(String name) {
        return roleRepository.findRoleByName(name);
    }

    @Transactional(transactionManager = "transactionManager")
    public void delete(Role role) {
        role.setDeleted(true);
        roleRepository.save(role);
    }

    public List<Permission> getPermissions(Long roleId) {
        List<RolePermission> rolePermissions = rolePermissionsRepository.findAllByRoleId(roleId);
        List<Permission> permissions = rolePermissions.stream()
                .map(RolePermission::getPermission).collect(Collectors.toList());
        return permissions;
    }

    public List<PermissionDTO> getPermissionsWithStatus(Long roleId) {
        List<PermissionDTO> permissionsWithStatus = new ArrayList<>();

        List<Permission> rolePermissions = getPermissions(roleId);

        List<Permission> allPermissions = permissionService.getAllPermissions();

        for (Permission permission : allPermissions) {
            if (rolePermissions.contains(permission)) {
                permissionsWithStatus.add(new PermissionDTO(
                        permission.getId(),
                        permission.getName(),
                        permission.getDescr(),
                        permission.getAlias(),
                        permission.getGroup(),
                        true)
                );
            } else {
                permissionsWithStatus.add(new PermissionDTO(
                        permission.getId(),
                        permission.getName(),
                        permission.getDescr(),
                        permission.getAlias(),
                        permission.getGroup(),
                        false)
                );
            }

        }
        return permissionsWithStatus;
    }

    public List<RolePermission> getRolePermissions(Long roleId) {
        return rolePermissionsRepository.findAllByRoleId(roleId);
    }

    @Transactional(transactionManager = "transactionManager")
    public void saveRolePermissions(Role role, List<Permission> permissions) {
        rolePermissionsRepository.deleteAllByRoleId(role.getId());
        List<Long> ids = permissions.stream().map(Permission::getId).collect(Collectors.toList());
        List<Permission> dbPermissions = permissionService.findAllByIds(ids);
        if(dbPermissions != null && !dbPermissions.isEmpty()) {
            List<RolePermission> forSave = new ArrayList<>();
            for (Permission permission : dbPermissions) {
                RolePermission rolePermissions = RolePermission.builder()
                        .permission(permission)
                        .role(role)
                        .build();
                forSave.add(rolePermissions);
            }
            role.setPermissions(forSave);
            roleRepository.save(role);
            //rolePermissionsRepository.saveAll(forSave);
        }
    }

    @Transactional(transactionManager = "transactionManager", propagation = Propagation.REQUIRES_NEW)
    public void saveRolesByIds(UserProfile userProfile, List<Long> ids) {
        List<Role> dbRoles = roleRepository.findByIdIn(ids);
        if(dbRoles != null && !dbRoles.isEmpty()) {
            List<UserRoles> forSave = new ArrayList<>();
            for(Role role : dbRoles) {
                UserRoles userRole = UserRoles.builder()
                        .userProfile(userProfile)
                        .role(role)
                        .build();
                forSave.add(userRole);
            }
            userRolesRepository.saveAll(forSave);
        }
    }

    public void deleteAllByUserProfileId(Long id) {
        userRolesRepository.deleteAllByUserProfileId(id);
    }
}
