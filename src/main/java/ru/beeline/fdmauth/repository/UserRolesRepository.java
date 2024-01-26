package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.UserRoles;


@Repository
public interface UserRolesRepository extends JpaRepository<UserRoles, Long> {
    void deleteAllByUserProfileId(Long userProfileId);
}
