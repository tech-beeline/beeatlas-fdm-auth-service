package ru.beeline.fdmauth.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.dto.PermissionTypeDTO;
import ru.beeline.fdmauth.repository.PermissionRepository;
import ru.beeline.fdmauth.dto.PermissionDTO;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class PermissionService {

    @Autowired
    private PermissionRepository permissionRepository;


    public List<Permission> getAllPermissions() {
        return permissionRepository.findAll();
    }

    public List<Permission> findAllByIds(List<Long> ids) {
        return permissionRepository.findByIdIn(ids);
    }

    public Set<PermissionDTO> getUserPermissions(Set<Permission> rolePermissions) {
        Set<PermissionDTO> userPermissions = new HashSet<>();

        List<Permission> allPermissions = getAllPermissions();

        for(Permission permission : allPermissions) {
            if(rolePermissions.contains(permission)){
                userPermissions.add(new PermissionDTO(
                        permission.getId(),
                        permission.getName(),
                        permission.getDescr(),
                        PermissionTypeDTO.valueOf(permission.getAlias().name()),
                        true)
                );
            } else {
                userPermissions.add(new PermissionDTO(
                        permission.getId(),
                        permission.getName(),
                        permission.getDescr(),
                        PermissionTypeDTO.valueOf(permission.getAlias().name()),
                        false)
                );
            }
        }
        return userPermissions;
    }
}
