package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.UserProfile;


@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, Long> {
    UserProfile findByLogin(String login);
}
