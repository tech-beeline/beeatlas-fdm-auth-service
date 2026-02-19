/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.Role;
import java.util.List;
import java.util.Optional;


@Repository
public interface RoleRepository extends JpaRepository<Role, Long> {
    Role findRoleByName(String name);
    List<Role> findByIdIn(List<Long> idList);


    @Query("SELECT r FROM Role r WHERE lower(r.alias) = lower(:alias) AND r.deleted = false")
    Optional<List<Role>> findAllByAliasAndDeletedFalse(@Param("alias") String alias);
}
