package ru.beeline.fdmauth.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.beeline.fdmauth.domain.*;
import ru.beeline.fdmauth.dto.UserInfoDTO;
import ru.beeline.fdmauth.exception.UserNotFoundException;
import ru.beeline.fdmauth.repository.UserProfileRepository;
import ru.beeline.fdmauth.dto.role.RoleInfoDTO;
import ru.beeline.fdmauth.dto.UserProfileDTO;
import java.sql.Date;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class UserService {

    @Autowired
    private UserProfileRepository userProfileRepository;

    @Autowired
    private RoleService roleService;

    @Autowired
    private ProductService productService;

    public List<UserProfile> getAllUsers() {
        return userProfileRepository.findAll();
    }

    public UserProfileDTO createUserProfileVM(UserProfileDTO userProfileVM) {
        UserProfile userProfile = createUserProfile(userProfileVM);
        if(userProfile != null) return new UserProfileDTO(userProfile);
        else return null;
    }

    @Transactional(transactionManager = "transactionManager")
    public UserProfile createUserProfile(UserProfileDTO userProfileVM) {
        UserProfile newUser = UserProfile.builder()
                .idExt(userProfileVM.getIdExt())
                .fullName(userProfileVM.getFullName())
                .login(userProfileVM.getLogin())
                .lastLogin(new Date(System.currentTimeMillis()))
                .email(userProfileVM.getEmail())
                .build();
        userProfileRepository.save(newUser);
        if(userProfileVM.getRoles() != null) {
            List<Long> ids = userProfileVM.getRoles().stream().map(RoleInfoDTO::getId).collect(Collectors.toList());
            roleService.saveRolesByIds(newUser, ids);
        } else {
            roleService.saveRolesByIds(newUser, Collections.singletonList(1L));
        }
        Optional<UserProfile> userProfile = userProfileRepository.findById(newUser.getId());
        return userProfile.orElse(null);
    }

    public UserProfile createUser(String idExt,  String fullName, String login, String email){
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

    public Optional<UserProfile> findProfileById(Long id) {
        return userProfileRepository.findById(id);
    }

    public UserProfile findProfileByLogin(String login) {
        return userProfileRepository.findUserProfileByLogin(login);
    }

    public UserProfile findProfileByEmail(String email) {
        return userProfileRepository.findUserProfileByEmail(email);
    }

    public Long hasLinkProductIdWithProfileId(Long profileId, String productId) {
        return userProfileRepository.hasLinkProductIdWithProfileId(profileId, productId);
    }

    @Transactional(transactionManager = "transactionManager")
    public UserProfileDTO setRoles(UserProfile userProfile, List<RoleInfoDTO> roles) {
        List<Long> ids = roles.stream().map(RoleInfoDTO::getId).collect(Collectors.toList());
        if(!ids.isEmpty()) {
            roleService.deleteAllByUserProfileId(userProfile.getId());
            roleService.saveRolesByIds(userProfile, ids);
        }

        Optional<UserProfile> updatedUserProfile = userProfileRepository.findById(userProfile.getId());
        return updatedUserProfile.map(UserProfileDTO::new).orElse(null);
    }

    @Transactional(transactionManager = "transactionManager")
    public void updateLastLogin(UserProfile userProfile) {
        userProfile.setLastLogin(new Date(System.currentTimeMillis()));
        userProfileRepository.save(userProfile);
    }

    public Boolean checkProductExistenceById(Long id) {
        Optional<UserProfile> userOpt = userProfileRepository.findById(id);
        return userOpt.isPresent();
    }
    @Transactional(transactionManager = "transactionManager")
    public UserInfoDTO getInfo(String login, String email, String fullName, String idExt) {
        UserProfile userProfile = findProfileByLogin(login);
        if(userProfile == null) {
            userProfile = createUser(idExt, fullName, login, email);
            roleService.saveRolesByIds(userProfile, Collections.singletonList(1L));
            productService.findOrCreateProducts(userProfile);

            Optional<UserProfile> userOpt = userProfileRepository.findById(userProfile.getId());
            userProfile = userOpt.orElse(null);
        } else {
            if(userProfile.getUserProducts() == null || userProfile.getUserProducts().isEmpty()) {
                productService.findOrCreateProducts(userProfile);
            }
        }
        if(userProfile != null) {
            return UserInfoDTO.builder()
                    .id(userProfile.getId())
                    .productsIds(userProfile.getUserProducts() != null ?
                            userProfile.getUserProducts().stream()
                                    .map(up -> up.getProduct().getId()).collect(Collectors.toList()) : new ArrayList<>())
                    .roles(userProfile.getUserRoles() != null ?
                            userProfile.getUserRoles().stream()
                                    .map(ur -> ur.getRole().getAlias()).collect(Collectors.toList()) : new ArrayList<>())
                    .permissions(getPermissionsByUser(userProfile))
                    .build();
        } else throw new UserNotFoundException("404 Пользователь не найден");
    }

    private List<Permission.PermissionType> getPermissionsByUser(UserProfile userProfile) {
        Set<Permission.PermissionType> permissionTypes = new HashSet<>();
        if(userProfile.getUserRoles() != null) {
            for(UserRoles userRole : userProfile.getUserRoles()) {
                List<RolePermission> rolePermissions = userRole.getRole().getPermissions();
                if(rolePermissions != null) {
                    permissionTypes.addAll(rolePermissions.stream().map(rp -> rp.getPermission().getAlias()).toList());
                }
            }
        }

        return permissionTypes.stream().toList();
    }
}
