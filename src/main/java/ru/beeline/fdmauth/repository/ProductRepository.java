package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.Product;
import java.util.List;


@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    @Query(value = "SELECT p.* FROM user_auth.product p " +
            "INNER JOIN user_auth.user_product upr ON p.id = upr.id_product " +
            "WHERE upr.id_profile = ?1", nativeQuery = true)
    List<Product> getProductsByProfileId(Integer idProfile);

    Product findAllByAlias(String alias);
}