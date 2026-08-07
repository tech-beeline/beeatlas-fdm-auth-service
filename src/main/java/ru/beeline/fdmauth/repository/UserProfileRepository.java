/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.UserProfile;

import java.util.List;


@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, Integer> {
    @Query("SELECT DISTINCT up FROM UserProfile up " +
            "JOIN up.userRoles ur " +
            "JOIN ur.role r " +
            "WHERE lower(r.alias) = lower(:alias) AND r.deleted = false")
    List<UserProfile> findAllByRoleAlias(@Param("alias") String alias);

    @Query("SELECT DISTINCT u FROM UserProfile u LEFT JOIN FETCH u.userRoles ur LEFT JOIN FETCH ur.role")
    List<UserProfile> findAllWithRoles();

    UserProfile findByLogin(String login);

    UserProfile findByIdExt(String idExt);

    List<UserProfile> findAllByIdIn(List<Integer> ids);
}
