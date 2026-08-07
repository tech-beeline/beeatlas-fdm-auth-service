/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.repository.rbac;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.rbac.Policy;
import ru.beeline.fdmauth.domain.rbac.Route;

import java.util.List;
import java.util.Optional;

@Repository
public interface PolicyRepository extends JpaRepository<Policy, Long> {

    @Query("SELECT p FROM Policy p JOIN FETCH p.route")
    List<Policy> findAllWithRoute();

    @Query("SELECT p FROM Policy p WHERE p.route.id IN :routeIds")
    List<Policy> findByRouteIds(@Param("routeIds") List<Long> routeIds);

    @Query("SELECT p FROM Policy p WHERE p.route = :route " +
           "AND (:roleAlias IS NULL AND p.roleAlias IS NULL OR p.roleAlias = :roleAlias) " +
           "AND (:permissionAlias IS NULL AND p.permissionAlias IS NULL OR p.permissionAlias = :permissionAlias) " +
           "AND p.effect = :effect")
    Optional<Policy> findConflicting(@Param("route") Route route,
                                     @Param("roleAlias") String roleAlias,
                                     @Param("permissionAlias") String permissionAlias,
                                     @Param("effect") String effect);
}
