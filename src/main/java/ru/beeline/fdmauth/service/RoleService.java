package ru.beeline.fdmauth.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.HttpClientErrorException;
import ru.beeline.fdmauth.domain.*;
import ru.beeline.fdmauth.dto.role.RoleCreateDTO;
import ru.beeline.fdmauth.dto.role.RoleDTO;
import ru.beeline.fdmauth.exception.DefaultRoleException;
import ru.beeline.fdmauth.exception.EntityNotFoundException;
import ru.beeline.fdmauth.exception.NameConflictException;
import ru.beeline.fdmauth.exception.RoleConflictException;
import ru.beeline.fdmauth.repository.RolePermissionsRepository;
import ru.beeline.fdmauth.repository.RoleRepository;
import ru.beeline.fdmauth.repository.UserRolesRepository;
import ru.beeline.fdmauth.dto.PermissionDTO;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Slf4j
public class RoleService {

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private RolePermissionsRepository rolePermissionsRepository;

    @Autowired
    private UserRolesRepository userRolesRepository;

    @Autowired
    private PermissionService permissionService;

    public List<Role> getAllNotDeletedRoles() {
        List<Role> roles = roleRepository.findAll();
        if(roles.isEmpty()) {
            roles = new ArrayList<>();
        } else {
            roles.removeIf(Role::isDeleted);
            for (Role role : roles) {
                if (role.getPermissions().isEmpty()) {
                    List<RolePermission> rolePermissions = getRolePermissions(role.getId());
                    if (!rolePermissions.isEmpty()) role.setPermissions(rolePermissions);
                }
            }
        }
        return roles;
    }

    @Transactional(transactionManager = "transactionManager")
    public Role createRole(RoleCreateDTO role) {
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
    public Role updateRole(Long id, RoleDTO role) {
        if (id != null) {
            if (id >= 1 && id <= 8) {
                String roleName = Role.RoleType.getNameById(id.intValue()-1);
                String errText = String.format("Редактируемая роль '%s' является дефолтной", roleName);
                throw new DefaultRoleException(errText);
            } else {
                Optional<Role> currentRoleOpt = findRole(id);
                if (currentRoleOpt.isPresent()) {
                    Role roleWithSuchName = findRoleByName(role.getName());
                    if (roleWithSuchName != null) {
                        if (roleWithSuchName.getId() != id) {
                            String errText;
                            if(roleWithSuchName.getId()>= 1 && roleWithSuchName.getId() <= 8){
                                errText = String.format("Конфликт: роль с именем '%s' уже существует и является дефолтной, нельзя менять имя роли на дефолтное", roleWithSuchName.getName());
                            } else {
                                errText = String.format("Конфликт: роль с именем '%s' уже существует", roleWithSuchName.getName());
                            }
                            throw new DefaultRoleException(errText);
                        } else return changeRole(id, role);
                    }
                    return changeRole(id, role);
                } else {
                    String errText = String.format("404 Роль c id='%d' не найдена", id);
                    throw new EntityNotFoundException(errText);
                }
            }
        } else {
            String errText = "409 role.id не может быть null";
            throw new RoleConflictException(errText);
        }
    }

    private Role changeRole(Long id, RoleDTO role) {
        Optional<Role> currentRoleOpt = roleRepository.findById(id);
        if(currentRoleOpt.isEmpty()) throw new HttpClientErrorException(HttpStatus.NOT_FOUND);
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
                        true)
                );
            } else {
                permissionsWithStatus.add(new PermissionDTO(
                        permission.getId(),
                        permission.getName(),
                        permission.getDescr(),
                        permission.getAlias(),
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

    @Transactional(transactionManager = "transactionManager")
    public Role createNewRole(RoleCreateDTO role) {
        boolean isExist = checkNameIsUnique(role.getName());
        if (isExist) {
            String errText = String.format("Конфликт: Роль с именем '%s' уже существует", role.getName());
            throw new NameConflictException(errText);
        } else {
            Role newRole = createRole(role);
            List<Permission> permissions = new ArrayList<>();
            permissions.add(new Permission(1));
            permissions.add(new Permission(2));
            permissions.add(new Permission(3));
            saveRolePermissions(newRole, permissions);
            return newRole;
        }
    }
}
