package ru.beeline.fdmauth.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.domain.Product;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.dto.bw.BWRole;
import ru.beeline.fdmauth.dto.bw.EmployeeProductsDTO;
import ru.beeline.fdmauth.repository.ProductRepository;
import ru.beeline.fdmauth.utils.jwt.JwtUtils;

import java.util.ArrayList;
import java.util.List;

@Service
@Slf4j
public class ProductService {
    @Autowired
    ProductRepository productRepository;

    @Autowired
    private UserProfileService userProfileService;

    @Autowired
    private BWEmployeeService bwEmployeeService;

    public Product findProductById(Long productId) {
        return productRepository.findById(productId).orElseGet(null);
    }

    public List<Product> findProductsByPermission(String bearerToken) {
        String email = JwtUtils.getEmail(bearerToken);
        UserProfile user = userProfileService.findProfileByEmail(email);
        return findProductsByUser(user);
    }

    public List<Product> findProductsByUser(UserProfile user) {
        if(user.getUserRoles() == null) return new ArrayList<>();
        if (user.getUserRoles().stream().anyMatch(userRoles ->
                userRoles.getRole().getPermissions().stream().anyMatch(rolePermissions ->
                        rolePermissions.getPermission().getAlias() == Permission.PermissionType.DESIGN_ARTIFACT))) {
            return productRepository.findAll();
        } else {
            return productRepository.getProductsByProfileId(user.getId());
        }
    }

    public Product createProduct(BWRole bwRole) {
        Product product = Product.builder()
                    .name(bwRole.getProductName())
                    .alias(bwRole.getCmdbCode())
                    .build();
        return productRepository.save(product);
    }
    public List<Product> createProducts(List<BWRole> bwRoles) {
        List<Product> products = new ArrayList<>();
        for(BWRole bwRole : bwRoles) {
            Product product = Product.builder()
                    .name(bwRole.getProductName())
                    .alias(bwRole.getCmdbCode())
                    .build();
            products.add(product);
        }
        return productRepository.saveAll(products);
    }

    @Transactional(transactionManager = "transactionManager")
    public List<Product> findOrCreateProducts(UserProfile userProfile) {
        List<Product> products = new ArrayList<>();

        EmployeeProductsDTO employeeProductsDTO = bwEmployeeService.getEmployeeInfo(userProfile.getLogin());

        if (employeeProductsDTO != null && !employeeProductsDTO.getBwRoles().isEmpty()) {

            for(BWRole bwRole : employeeProductsDTO.getBwRoles()) {
                Product product = productRepository.findAllByAlias(bwRole.getCmdbCode());
                if(product == null) {
                    try {
                        product = createProduct(bwRole);
                    } catch (Exception e) {
                        log.error(e.getMessage());
                    }
                }
                products.add(product);
            }
        }
        return products;
    }
}
