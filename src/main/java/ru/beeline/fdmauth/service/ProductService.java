package ru.beeline.fdmauth.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import ru.beeline.fdmauth.client.BWEmployeeClient;
import ru.beeline.fdmauth.client.ProductClient;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.domain.Product;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.dto.bw.BWRole;
import ru.beeline.fdmauth.dto.bw.EmployeeProductsDTO;
import ru.beeline.fdmauth.exception.EntityNotFoundException;
import ru.beeline.fdmauth.repository.ProductRepository;
import ru.beeline.fdmauth.repository.UserProfileRepository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Slf4j
public class ProductService {
    @Autowired
    ProductRepository productRepository;
    @Autowired
    UserProfileRepository userProfileRepository;

    @Autowired
    ProductClient productClient;

    @Autowired
    private BWEmployeeClient bwEmployeeClient;

    public List<Product> findProductsByUserId(Integer id) {
        return findProductsByUser(userProfileRepository.findById(id)
                                          .orElseThrow(() -> new EntityNotFoundException(String.format(
                                                  "404 Пользователь c id '%s' не найден",
                                                  id))));
    }

    public List<Product> findProductsByUser(UserProfile user) {
        if (user.getUserRoles() == null)
            return new ArrayList<>();
        if (user.getUserRoles()
                .stream()
                .anyMatch(userRoles -> userRoles.getRole()
                        .getPermissions()
                        .stream()
                        .anyMatch(rolePermissions -> rolePermissions.getPermission()
                                .getAlias() == Permission.PermissionType.DESIGN_ARTIFACT))) {
            return productRepository.findAll();
        } else {
            return productRepository.getProductsByProfileId(user.getId());
        }
    }

    public void updateProducts(UserProfile userProfile) {
        EmployeeProductsDTO employeeProductsDTO = bwEmployeeClient.getEmployeeInfo(userProfile.getLogin());
        if (employeeProductsDTO != null && employeeProductsDTO.getBwRoles() != null && !employeeProductsDTO.getBwRoles()
                .isEmpty()) {
            List<String> codes = employeeProductsDTO.getBwRoles()
                    .stream()
                    .map(BWRole::getCmdbCode)
                    .collect(Collectors.toList());
            productClient.postProduct(codes, userProfile.getId().toString());
        } else {
            productClient.postProduct(List.of("BLN"), userProfile.getId().toString());
        }
    }

    public Boolean checkProductExistenceById(Long id) {
        Optional<Product> productOpt = productRepository.findById(id);
        return productOpt.isPresent();
    }
}

