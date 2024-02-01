package ru.beeline.fdmauth.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.exception.UnauthorizedException;
import ru.beeline.fdmauth.repository.UserProfileRepository;
import ru.beeline.fdmauth.utils.jwt.JwtUserData;
import ru.beeline.fdmauth.utils.jwt.JwtUtils;
import ru.beeline.fdmauth.dto.RoleDTO;
import ru.beeline.fdmauth.dto.UserProfileDTO;

import java.sql.Date;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class UserProfileService {

    @Autowired
    private UserProfileRepository userProfileRepository;

    @Autowired
    private RoleService roleService;

    public List<UserProfile> getAllUsers() {
        return userProfileRepository.findAll();
    }

    public UserProfileDTO createUserProfileVM(UserProfileDTO userProfileVM) {
        UserProfile userProfile = createUserProfile(userProfileVM);
        if(userProfile != null) return new UserProfileDTO(userProfile);
        else return null;
    }

    @Transactional(transactionManager = "transactionManager")
    public UserProfile createUser(JwtUserData userData) {
        UserProfile newUser = UserProfile.builder()
                .idExt(userData.getEmployeeNumber())
                .fullName(userData.getFullName())
                .login(userData.getWinAccountName())
                .lastLogin(new Date(System.currentTimeMillis()))
                .email(userData.getEmail())
                .build();
        userProfileRepository.save(newUser);
        return newUser;
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
            List<Long> ids = userProfileVM.getRoles().stream().map(RoleDTO::getId).collect(Collectors.toList());
            roleService.saveRolesByIds(newUser, ids);
        } else {
            roleService.saveRolesByIds(newUser, Collections.singletonList(1L));
        }
        Optional<UserProfile> userProfile = userProfileRepository.findById(newUser.getId());
        return userProfile.orElse(null);
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
    public UserProfileDTO editUserProfile(UserProfile userProfile, UserProfileDTO userProfileVM) {
        userProfile.setIdExt(userProfileVM.getIdExt());
        userProfile.setFullName(userProfileVM.getFullName());
        userProfile.setLogin(userProfileVM.getLogin());
        userProfile.setEmail(userProfileVM.getEmail());
        userProfileRepository.save(userProfile);

        roleService.deleteAllByUserProfileId(userProfile.getId());
        List<Long> ids = userProfileVM.getRoles().stream().map(RoleDTO::getId).collect(Collectors.toList());
        roleService.saveRolesByIds(userProfile, ids);
        Optional<UserProfile> updatedUserProfile = userProfileRepository.findById(userProfile.getId());
        return updatedUserProfile.map(UserProfileDTO::new).orElse(null);
    }

    @Transactional(transactionManager = "transactionManager")
    public UserProfileDTO setRoles(UserProfile userProfile, List<RoleDTO> roles) {
        List<Long> ids = roles.stream().map(RoleDTO::getId).collect(Collectors.toList());
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

    public void validateAccessProduct(String bearerToken, String productId) {
        String email = JwtUtils.getEmail(bearerToken);
        UserProfile user = findProfileByEmail(email);
        if (hasLinkProductIdWithProfileId(user.getId(), productId) == 0L &&
                user.getUserRoles().stream().noneMatch(userRoles ->
                        userRoles.getRole().getPermissions().stream().anyMatch(rolePermissions ->
                                rolePermissions.getPermission().getAlias() == Permission.PermissionType.DESIGN_ARTIFACT)
                )) {
            throw new UnauthorizedException("FORBIDDEN");
        }
    }
}
