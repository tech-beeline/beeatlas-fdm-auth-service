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

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@Slf4j
public class ProductService {
    @Autowired
    ProductRepository productRepository;

    @Autowired
    private BWEmployeeService bwEmployeeService;

    public Product findProductById(Long productId) {
        return productRepository.findById(productId).orElseGet(null);
    }

    public List<Product> findProductsByUser(UserProfile user) {
        if (user.getUserRoles() == null) return new ArrayList<>();
        if (user.getUserRoles().stream().anyMatch(userRoles ->
                userRoles.getRole().getPermissions().stream().anyMatch(rolePermissions ->
                        rolePermissions.getPermission().getAlias() == Permission.PermissionType.DESIGN_ARTIFACT))) {
            return productRepository.findAll();
        } else {
            return productRepository.getProductsByProfileId(user.getId());
        }
    }

    @Transactional(transactionManager = "transactionManager")
    public List<Product> findOrCreateProducts(UserProfile userProfile) {
        List<Product> products = new ArrayList<>();

        EmployeeProductsDTO employeeProductsDTO = bwEmployeeService.getEmployeeInfo(userProfile.getLogin());

        if (employeeProductsDTO != null && employeeProductsDTO.getBwRoles() != null && !employeeProductsDTO.getBwRoles().isEmpty()) {

            for (BWRole bwRole : employeeProductsDTO.getBwRoles()) {
                Product product = productRepository.findAllByAlias(bwRole.getCmdbCode());
                if (product == null) {
                    try {
                        product = productRepository.findById(0L).get();
                    } catch (Exception e) {
                        log.error(e.getMessage());
                    }
                }
                if (product != null && !products.contains(product)) {
                    products.add(product);
                }
            }
        } else {
            products.add(productRepository.findById(0L).get());
        }
        return products;
    }

    public Boolean checkProductExistenceById(Long id) {
        Optional<Product> productOpt = productRepository.findById(id);
        return productOpt.isPresent();
    }
}
