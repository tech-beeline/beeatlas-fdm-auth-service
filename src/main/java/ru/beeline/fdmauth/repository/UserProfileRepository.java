package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.UserProfile;


@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, Long> {
    UserProfile findUserProfileByLogin(String login);

    UserProfile findUserProfileByEmail(String email);

    @Query(value = "SELECT COUNT(*) FROM user_product_ext " +
            "WHERE user_product_ext.id_profile = :profileId AND user_product_ext.id_product_ext = :productId", nativeQuery = true)
    Long hasLinkProductIdWithProfileId(@Param("profileId") Long profileId, @Param("productId") String productId);
}
