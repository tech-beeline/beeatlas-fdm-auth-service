package ru.beeline.fdmauth.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.beeline.fdmauth.client.ProductClient;
import ru.beeline.fdmauth.domain.RolePermission;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.domain.UserRoles;
import ru.beeline.fdmauth.dto.ProductDTO;
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

    @Autowired
    private ProductClient productClient;

    public List<UserProfile> getAllUsers() {
        return userProfileRepository.findAll();
    }

    public UserInfoDTO getUserInfo(String login,
                                   String email,
                                   String fullName,
                                   String idExt) {
        validateFields(login, email, fullName, idExt);
        log.info("login is " + login);
        UserProfile userProfile = findProfileByLogin(login);
        List<Long> productIds = new ArrayList<>();
        if (userProfile == null) {
            log.info("userProfile is null, create new");
            userProfile = createNewUserAndProducts(login, email, fullName, idExt);
            addDefaultRole(userProfile);
            userProfile = findUserById(userProfile.getId());
            log.info("userProfile has been created with id=" + userProfile.getId());
        }
        List<ProductDTO> productDTOList = productClient.getProductByUserID(userProfile.getId());
        productDTOList.forEach(productDTO -> productIds.add((long) productDTO.getId()));
        return getInfo(userProfile, productIds);
    }

    private void validateFields(String login, String email, String fullName, String idExt) {
        if (login == null || login.length() > 50) {
            throw new RuntimeException("Login must not be null and must be at most 50 characters long.");
        }

        if (email == null || email.length() > 100) {
            throw new RuntimeException("Email must not be null, must be at most 100 characters long, and must be a valid email address.");
        }

        if (fullName == null || fullName.length() > 255) {
            throw new RuntimeException("Full name must not be null and must be at most 255 characters long.");
        }

        if (idExt == null || idExt.length() > 50) {
            throw new RuntimeException("External ID must not be null and must be at most 50 characters long.");
        }
    }

    public UserProfile createUser(String idExt, String fullName, String login, String email) {
        UserProfile newUser = UserProfile.builder()
                .idExt(idExt)
                .fullName(fullName)
                .login(login)
                .lastLogin(new Date(System.currentTimeMillis()))
                .email(email)
                .build();
        log.info("Create new User:" + newUser);
        userProfileRepository.save(newUser);
        return newUser;
    }

    public UserProfile findUserById(Long id) {
        return userProfileRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException(String.format("404 Пользователь c id '%s' не найден", id)));
    }

    public UserProfile findProfileByLogin(String login) {
        return userProfileRepository.findByLogin(login);
    }

    @Transactional(transactionManager = "transactionManager")
    public UserProfileDTO setRoles(UserProfile userProfile, List<RoleInfoDTO> roles) {
        List<Long> ids = roles.stream().map(RoleInfoDTO::getId).collect(Collectors.toList());
        if (!ids.isEmpty()) {
            roleService.deleteAllByUserProfileId(userProfile.getId());
            roleService.saveRolesByIds(userProfile, ids);
        }
        userProfileRepository.save(userProfile);

        Optional<UserProfile> updatedUserProfile = userProfileRepository.findById(userProfile.getId());
        return updatedUserProfile.map(UserProfileDTO::new).orElse(null);
    }

    public Boolean checkProductExistenceById(Long id) {
        Optional<UserProfile> userOpt = userProfileRepository.findById(id);
        return userOpt.isPresent();
    }

    public UserInfoDTO getInfo(UserProfile userProfile, List<Long> productIds) {
        if (userProfile != null) {
            List<UserRoles> userRoles = roleService.findUserRolesByUser(userProfile);
            log.info("userRoles size is " + userRoles.size());
            return UserInfoDTO.builder()
                    .id(userProfile.getId())
                    .productsIds(productIds)
                    .roles(userRoles != null ?
                            userRoles.stream()
                                    .map(ur -> RoleTypeDTO.valueOf(ur.getRole().getAlias().name())).collect(Collectors.toList()) : new ArrayList<>())
                    .permissions(getPermissionsByUser(userProfile))
                    .build();
        } else throw new UserNotFoundException("404 Пользователь не найден");
    }

    private List<PermissionTypeDTO> getPermissionsByUser(UserProfile userProfile) {
        Set<PermissionTypeDTO> permissionTypes = new HashSet<>();
        log.info("try fill permission");
        if (userProfile.getUserRoles() != null) {
            log.info("check each roles");
            for (UserRoles userRole : userProfile.getUserRoles()) {
                log.info("check role " + userRole.getId());
                List<RolePermission> rolePermissions = userRole.getRole().getPermissions();
                if (rolePermissions != null) {
                    log.info("check permissions count " + rolePermissions.size());
                    permissionTypes.addAll(rolePermissions.stream().map(rp -> PermissionTypeDTO.valueOf(rp.getPermission().getAlias().name())).toList());
                }
                log.info("permissions is " + permissionTypes);
            }
        }

        return permissionTypes.stream().toList();
    }

    @Transactional(transactionManager = "transactionManager")
    public UserProfile createNewUserAndProducts(String login, String email, String fullName, String idExt) {
        UserProfile newUser = createUser(idExt, fullName, login, email);
        productService.updateProducts(newUser);
        return newUser;
    }

    public void addDefaultRole(UserProfile newUser) {
        roleService.saveRolesByIds(newUser, Collections.singletonList(DEFAULT_ROLE_ID));
        userProfileRepository.save(newUser);
    }

    public String getEmailById(Long userId) {
        return findUserById(userId).getEmail();
    }
}
