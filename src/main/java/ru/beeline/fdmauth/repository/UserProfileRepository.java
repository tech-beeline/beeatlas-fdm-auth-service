package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.Role;
import ru.beeline.fdmauth.domain.UserProfile;

import java.util.List;
import java.util.Optional;


@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, Integer> {
    @Query("SELECT DISTINCT up FROM UserProfile up " +
            "JOIN up.userRoles ur " +
            "JOIN ur.role r " +
            "WHERE lower(r.alias) = lower(:alias) AND r.deleted = false")
    List<UserProfile> findAllByRoleAlias(@Param("alias") String alias);
    UserProfile findByLogin(String login);
}
