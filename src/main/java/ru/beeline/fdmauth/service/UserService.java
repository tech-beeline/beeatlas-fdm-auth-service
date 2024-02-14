package ru.beeline.fdmauth.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.repository.UserProfileRepository;
import ru.beeline.fdmauth.dto.role.RoleInfoDTO;
import ru.beeline.fdmauth.dto.UserProfileDTO;
import java.sql.Date;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class UserService {

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

}
