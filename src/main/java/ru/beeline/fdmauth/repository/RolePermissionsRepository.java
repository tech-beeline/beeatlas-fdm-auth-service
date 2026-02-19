/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.RolePermission;
import java.util.List;


@Repository
public interface RolePermissionsRepository extends JpaRepository<RolePermission, Long> {
    List<RolePermission> findAllByRoleId(Long roleId);

    void deleteAllByRoleId(Long roleId);
}
