/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.domain.UserRoles;

import java.util.List;


@Repository
public interface UserRolesRepository extends JpaRepository<UserRoles, Long> {
    void deleteAllByUserProfileId(Integer userProfileId);

    List<UserRoles> findAllByUserProfile(UserProfile userProfile);

    @Query("SELECT DISTINCT ur FROM UserRoles ur JOIN FETCH ur.role r LEFT JOIN FETCH r.permissions rp LEFT JOIN FETCH rp.permission WHERE ur.userProfile = :userProfile")
    List<UserRoles> findAllByUserProfileWithRoles(@Param("userProfile") UserProfile userProfile);
}
