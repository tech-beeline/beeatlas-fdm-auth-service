package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.Product;
import java.util.List;


@Repository
public interface ProductRepository extends JpaRepository<Product, String> {

    @Query(value = "SELECT p.* FROM product p " +
            "INNER JOIN user_product_ext upr ON p.id_product_ext = upr.id_product_ext " +
            "WHERE upr.id_profile = ?1", nativeQuery = true)
    List<Product> getProductsByProfileId(Long idProfile);
}