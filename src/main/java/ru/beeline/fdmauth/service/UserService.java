package ru.beeline.fdmauth.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.beeline.fdmauth.domain.Product;
import ru.beeline.fdmauth.domain.RolePermission;
import ru.beeline.fdmauth.domain.UserProducts;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.domain.UserRoles;
import ru.beeline.fdmauth.dto.UserProfileDTO;
import ru.beeline.fdmauth.dto.role.RoleInfoDTO;
import ru.beeline.fdmauth.exception.EntityNotFoundException;
import ru.beeline.fdmauth.exception.UserNotFoundException;
import ru.beeline.fdmauth.repository.UserProfileRepository;
import ru.beeline.fdmlib.dto.auth.PermissionTypeDTO;
import ru.beeline.fdmlib.dto.auth.RoleTypeDTO;
import ru.beeline.fdmlib.dto.auth.UserInfoDTO;

import java.sql.Date;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
public class UserService {

    Long DEFAULT_ROLE_ID = 1L;

    @Autowired
    private UserProfileRepository userProfileRepository;

    @Autowired
    private RoleService roleService;

    @Autowired
    private ProductService productService;

    public List<UserProfile> getAllUsers() {
        return userProfileRepository.findAll();
    }

    @Transactional(transactionManager = "transactionManager")
    public UserProfile createUser(String idExt, String fullName, String login, String email) {
        UserProfile newUser = UserProfile.builder()
                .idExt(idExt)
                .fullName(fullName)
                .login(login)
                .lastLogin(new Date(System.currentTimeMillis()))
                .email(email)
                .build();
        userProfileRepository.save(newUser);
        return newUser;
    }

    public UserProfile findUserById(Long id) {
        return userProfileRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException(String.format("404 Пользователь c id '%s' не найден", id)));
    }

    public UserProfile findProfileByLogin(String login) {
        return userProfileRepository.findUserProfileByLogin(login);
    }

    @Transactional(transactionManager = "transactionManager")
    public UserProfileDTO setRoles(UserProfile userProfile, List<RoleInfoDTO> roles) {
        List<Long> ids = roles.stream().map(RoleInfoDTO::getId).collect(Collectors.toList());
        if (!ids.isEmpty()) {
            roleService.deleteAllByUserProfileId(userProfile.getId());
            roleService.saveRolesByIds(userProfile, ids);
        }

        Optional<UserProfile> updatedUserProfile = userProfileRepository.findById(userProfile.getId());
        return updatedUserProfile.map(UserProfileDTO::new).orElse(null);
    }

    public Boolean checkProductExistenceById(Long id) {
        Optional<UserProfile> userOpt = userProfileRepository.findById(id);
        return userOpt.isPresent();
    }

    @Transactional(transactionManager = "transactionManager")
    public void updateUserProducts(UserProfile userProfile, List<Product> products) {
        if (!products.isEmpty()) {
            List<UserProducts> userProducts = new ArrayList<>();
            for (Product product : products) {
                UserProducts userProduct = UserProducts.builder()
                        .product(product)
                        .userProfile(userProfile)
                        .build();
                userProducts.add(userProduct);
            }
            userProfile.setUserProducts(userProducts);
            userProfileRepository.save(userProfile);
        }
    }

    @Transactional(transactionManager = "transactionManager")
    public UserInfoDTO getUserInfo(String login,
                                   String email,
                                   String fullName,
                                   String idExt) {
        UserProfile userProfile = findProfileByLogin(login);
        log.info(String.format("UserProfile: %s", userProfile));
        if (userProfile == null) {
            userProfile = createNewUserAndProducts(login, email, fullName, idExt);
            log.info(String.format("Created userProfile: %s", userProfile));
        } else {
            if (userProfile.getUserProducts() == null
                    || userProfile.getUserProducts().isEmpty()) {
                findAndSaveProducts(userProfile);
                log.info(String.format("Product to userProfile was added: %s", userProfile.getUserProducts()));
            }
        }
        return getInfo(userProfile);
    }


    public UserInfoDTO getInfo(UserProfile userProfile) {
        if (userProfile != null) {
            List<UserRoles> userRoles = roleService.findUserRolesByUser(userProfile);
            log.info(String.format("UserRoles: %s", userRoles));
            return UserInfoDTO.builder()
                    .id(userProfile.getId())
                    .productsIds(userProfile.getUserProducts() != null ?
                            userProfile.getUserProducts().stream()
                                    .map(up -> up.getProduct().getId()).collect(Collectors.toList()) : new ArrayList<>())
                    .roles(userRoles != null ?
                            userRoles.stream()
                                    .map(role -> RoleTypeDTO.valueOf(role.getRole().getAlias().name())).collect(Collectors.toList()) : new ArrayList<>())
                    .permissions(getPermissionsByUser(userProfile))
                    .build();
        } else throw new UserNotFoundException("404 Пользователь не найден");
    }

    public void findAndSaveProducts(UserProfile userProfile) {
        List<Product> products = productService.findOrCreateProducts(userProfile);
        if (!products.isEmpty()) {
            updateUserProducts(userProfile, products);
        }
    }

    private List<PermissionTypeDTO> getPermissionsByUser(UserProfile userProfile) {
        Set<PermissionTypeDTO> permissionTypes = new HashSet<>();
        log.info(String.format("add permissions of userProfile: %s", userProfile));
        if (userProfile.getUserRoles() != null) {
            log.info(String.format("add permissions of userRole: %s", userProfile.getUserRoles()));
            for (UserRoles userRole : userProfile.getUserRoles()) {
                List<RolePermission> rolePermissions = userRole.getRole().getPermissions();
                log.info(String.format("add permissions of rolePermissions: %s", rolePermissions));
                if (rolePermissions != null) {
                    log.info(String.format("permission of role '%s': %s", userRole.getRole(), rolePermissions));
                    List<PermissionTypeDTO> permissions = rolePermissions.stream().map(rp -> PermissionTypeDTO.valueOf(rp.getPermission().getAlias().name())).toList();
                    log.info(String.format("add permissions: %s", permissions));
                    permissionTypes.addAll(permissions);
                }
            }
        }
        log.info(String.format("Permissions: %s", permissionTypes));
        return permissionTypes.stream().toList();
    }

    @Transactional(transactionManager = "transactionManager")
    public UserProfile createNewUserAndProducts(String login, String email, String fullName, String idExt) {
        UserProfile newUser = createUser(idExt, fullName, login, email);
        findAndSaveProducts(newUser);
        roleService.saveRolesByIds(newUser, Collections.singletonList(DEFAULT_ROLE_ID));
        return findUserById(newUser.getId());
    }

    public String getEmailById(Long userId) {
        return findUserById(userId).getEmail();
    }
}
