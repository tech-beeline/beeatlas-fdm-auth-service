/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import ru.beeline.fdmauth.client.ProductClient;
import ru.beeline.fdmauth.domain.Role;
import ru.beeline.fdmauth.domain.RolePermission;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.domain.UserRoles;
import ru.beeline.fdmauth.dto.*;
import ru.beeline.fdmauth.dto.role.RoleInfoDTO;
import ru.beeline.fdmauth.exception.EntityNotFoundException;
import ru.beeline.fdmauth.exception.UserNotFoundException;
import ru.beeline.fdmauth.repository.RoleRepository;
import ru.beeline.fdmauth.repository.UserProfileRepository;
import ru.beeline.fdmauth.repository.UserRolesRepository;

import java.sql.Date;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
public class UserProfileService {

    Long DEFAULT_ROLE_ID = 1L;

    Long ADMINISTRATOR_ROLE_ID = 2L;

    @Autowired
    private UserProfileRepository userProfileRepository;

    @Autowired
    private RoleService roleService;

    @Autowired
    private ProductService productService;

    @Autowired
    private ProductClient productClient;
    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private UserRolesRepository userRolesRepository;

    public List<UserProfile> getAllUsers() {
        return userProfileRepository.findAll();
    }

    public UserInfoDTO getUserInfo(String login, String email, String fullName, String idExt) {
        validateFields(login, email, fullName, idExt);
        log.info("Поиск user по login: " + login);
        if (login.equals("default")) {
            login = "defaultUser";
        }
        UserProfile userProfile = findProfileByLogin(login);
        List<Long> productIds = new ArrayList<>();
        if (userProfile == null) {
            log.info("userProfile is null, поиск по ext_id");
            userProfile = userProfileRepository.findByIdExt(idExt);
            if (userProfile != null) {
                log.info("userProfile с ext_id: {} найден, обновляем данные.", idExt);
                userProfile.setLogin(login);
                userProfile.setEmail(email);
                userProfile.setFullName(fullName);
                userProfileRepository.save(userProfile);
            } else {
                log.info("userProfile is null, создаем нового");
                userProfile = createNewUserAndProducts(login, email, fullName, idExt);
                addDefaultRole(userProfile);
                userProfile = findUserById(userProfile.getId());
                log.info("userProfile создан с id=" + userProfile.getId());
            }
        }
        List<UserRoles> userRoles = userRolesRepository.findAllByUserProfileWithRoles(userProfile);
        List<ProductDTO> productDTOList = productClient.getProductByUserID(userProfile.getId());
        if (productDTOList != null) {
            productDTOList.forEach(productDTO -> productIds.add((long) productDTO.getId()));
        }
        return buildUserInfo(userProfile, userRoles, productIds);
    }

    private void validateFields(String login, String email, String fullName, String idExt) {
        if (login == null || login.length() > 50) {
            throw new RuntimeException("Login must not be null and must be at most 50 characters long.");
        }

        if (email == null || email.length() > 100) {
            throw new RuntimeException(
                    "Email must not be null, must be at most 100 characters long, and must be a valid email address.");
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
                .fullName(decodeUnicodeSmart(fullName))
                .login(login)
                .lastLogin(new Date(System.currentTimeMillis()))
                .email(email)
                .build();
        log.info("Create new User:" + newUser);
        userProfileRepository.save(newUser);
        return newUser;
    }

    @Transactional(transactionManager = "transactionManager")
    public List<CreateUserResponseDTO> createUsers(List<CreateUserRequestDTO> users) {
        if (users == null || users.isEmpty()) {
            throw new IllegalArgumentException("Не переданы обязательные параметры");
        }

        Role defaultRole = roleRepository.findById(DEFAULT_ROLE_ID)
                .orElseThrow(() -> new EntityNotFoundException("404 Роль по умолчанию не найдена"));

        List<CreateUserResponseDTO> result = new ArrayList<>();
        for (CreateUserRequestDTO req : users) {
            if (req == null
                    || req.getLogin() == null || req.getFullName() == null || req.getIdExt() == null || req.getEmail() == null
                    || req.getLogin().isBlank() || req.getFullName().isBlank() || req.getIdExt().isBlank() || req.getEmail().isBlank()
            ) {
                throw new IllegalArgumentException("Не переданы обязательные параметры");
            }

            UserProfile existing = userProfileRepository.findByLogin(req.getLogin());
            if (existing != null) {
                result.add(CreateUserResponseDTO.builder()
                        .login(req.getLogin())
                        .fullName(req.getFullName())
                        .idExt(req.getIdExt())
                        .email(req.getEmail())
                        .id(existing.getId())
                        .build());
                continue;
            }

            UserProfile newUser = UserProfile.builder()
                    .idExt(req.getIdExt())
                    .fullName(decodeUnicodeSmart(req.getFullName()))
                    .login(req.getLogin())
                    .lastLogin(new Date(System.currentTimeMillis()))
                    .email(req.getEmail())
                    .build();
            userProfileRepository.saveAndFlush(newUser);

            UserRoles defaultUserRole = UserRoles.builder()
                    .userProfile(newUser)
                    .role(defaultRole)
                    .build();
            userRolesRepository.save(defaultUserRole);

            productService.updateProducts(newUser);

            result.add(CreateUserResponseDTO.builder()
                    .login(req.getLogin())
                    .fullName(req.getFullName())
                    .idExt(req.getIdExt())
                    .email(req.getEmail())
                    .id(newUser.getId())
                    .build());
        }
        return result;
    }

    public static String decodeUnicodeSmart(String input) {
        if (input == null) return null;

        StringBuilder result = new StringBuilder();
        for (int i = 0; i < input.length(); ) {
            if (i + 4 < input.length() &&
                    input.charAt(i) == 'u' &&
                    input.substring(i + 1, i + 5).matches("[0-9a-fA-F]{4}")) {

                int code = Integer.parseInt(input.substring(i + 1, i + 5), 16);
                result.append((char) code);
                i += 5;
            } else {
                result.append(input.charAt(i));
                i++;
            }
        }
        return result.toString();
    }

    public UserProfile findUserById(Integer id) {
        return userProfileRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException(String.format("404 Пользователь c id '%s' не найден",
                        id)));
    }

    public UserProfile findProfileByLogin(String login) {
        UserProfile userProfile = userProfileRepository.findByLogin(login);
        return userProfile;
    }

    @Transactional(readOnly = true, transactionManager = "transactionManager")
    public UserProfileDTO findProfileById(Integer id) {
        UserProfile userProfile = userProfileRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException(String.format("404 Пользователь c id '%s' не найден",
                        id)));
        return new UserProfileDTO(userProfile);
    }

    @Transactional(readOnly = true, transactionManager = "transactionManager")
    public List<UserProfileDTO> getAllUsersAsDTO() {
        return userProfileRepository.findAllWithRoles().stream()
                .map(UserProfileDTO::new)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true, transactionManager = "transactionManager")
    public UserProfileDTO findProfileByLoginAsDTO(String login) {
        UserProfile userProfile = userProfileRepository.findByLogin(login);
        if (userProfile == null) return null;
        return new UserProfileDTO(userProfile);
    }

    public List<UserRoles> getUserRolesWithPermissions(UserProfile userProfile) {
        return userRolesRepository.findAllByUserProfileWithRoles(userProfile);
    }

    public List<UserProfileShortV2DTO> findProfileByIdIn(List<Integer> ids) {
        List<UserProfileShortV2DTO> result = new ArrayList<>();
        if (!ids.isEmpty()) {
            List<UserProfile> userProfileList = userProfileRepository.findAllByIdIn(ids);
            if (!userProfileList.isEmpty()) {
                result = userProfileList.stream().map(userProfile -> UserProfileShortV2DTO.builder()
                        .email(userProfile.getEmail())
                        .fullName(userProfile.getFullName())
                        .login(userProfile.getLogin())
                        .id(userProfile.getId())
                        .idExt(userProfile.getIdExt())
                        .build()
                ).toList();
                return result;
            }
        }
        return result;
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

    public Boolean checkProductExistenceById(Integer id) {
        Optional<UserProfile> userOpt = userProfileRepository.findById(id);
        return userOpt.isPresent();
    }

    public UserInfoDTO getInfo(UserProfile userProfile, List<Long> productIds) {
        List<UserRoles> userRoles = userRolesRepository.findAllByUserProfileWithRoles(userProfile);
        return buildUserInfo(userProfile, userRoles, productIds);
    }

    public UserInfoDTO getUserInfoById(Integer id) {
        UserProfile userProfile = findUserById(id);
        List<UserRoles> userRoles = userRolesRepository.findAllByUserProfileWithRoles(userProfile);
        List<Long> productIds = new ArrayList<>();
        List<ProductDTO> productDTOList = productClient.getProductByUserID(userProfile.getId());
        if (productDTOList != null) {
            productDTOList.forEach(productDTO -> productIds.add((long) productDTO.getId()));
        }
        return buildUserInfo(userProfile, userRoles, productIds);
    }

    private UserInfoDTO buildUserInfo(UserProfile userProfile, List<UserRoles> userRoles, List<Long> productIds) {
        if (userProfile == null) throw new UserNotFoundException("404 Пользователь не найден");
        return UserInfoDTO.builder()
                .id(userProfile.getId())
                .productsIds(productIds)
                .roles(userRoles.stream()
                        .map(UserRoles::getRole)
                        .map(Role::getAlias)
                        .distinct()
                        .collect(Collectors.toList()))
                .permissions(getPermissionsByUserRoles(userRoles))
                .build();
    }

    private List<PermissionTypeDTO> getPermissionsByUserRoles(List<UserRoles> userRoles) {
        Set<PermissionTypeDTO> permissionTypes = new HashSet<>();
        for (UserRoles userRole : userRoles) {
            List<RolePermission> rolePermissions = userRole.getRole().getPermissions();
            if (rolePermissions != null) {
                permissionTypes.addAll(rolePermissions.stream()
                        .map(rp -> PermissionTypeDTO.valueOf(rp.getPermission().getAlias().name()))
                        .toList());
            }
        }
        return permissionTypes.stream().toList();
    }

    public List<UserProfileShortV2DTO> getAllUserProfileFdmV2() {
        List<UserProfileShortV2DTO> result = new ArrayList<>();
        List<UserProfile> userProfileList = userProfileRepository.findAll();
        if (!userProfileList.isEmpty()) {
            result = userProfileList.stream().map(userProfile -> UserProfileShortV2DTO.builder()
                    .email(userProfile.getEmail())
                    .fullName(userProfile.getFullName())
                    .login(userProfile.getLogin())
                    .id(userProfile.getId())
                    .idExt(userProfile.getIdExt())
                    .build()
            ).toList();
            return result;
        }
        return result;
    }

    public List<UserProfileShortDTO> getAllUserProfileFdm() {
        List<UserProfileShortDTO> result = new ArrayList<>();
        List<UserProfile> userProfileList = userProfileRepository.findAll();
        if (!userProfileList.isEmpty()) {
            result = userProfileList.stream().map(userProfile -> UserProfileShortDTO.builder()
                    .email(userProfile.getEmail())
                    .fullName(userProfile.getFullName())
                    .login(userProfile.getLogin())
                    .id(userProfile.getId())
                    .idExt(userProfile.getIdExt())
                    .build()
            ).toList();
            return result;
        }
        return result;
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

    public String getEmailById(Integer userId) {
        return findUserById(userId).getEmail();
    }

    public List<UserProfileShortV2DTO> getProfilesByRoleAlias(String aliasRole) {
        roleRepository.findAllByAliasAndDeletedFalse(aliasRole)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Роль не найдена"));

        List<UserProfile> profiles = userProfileRepository.findAllByRoleAlias(aliasRole);
        if (profiles.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Пользователь с данной ролью не найден");
        }
        return profiles.stream()
                .sorted(Comparator.comparing(UserProfile::getId))
                .map(profile -> UserProfileShortV2DTO.builder()
                        .email(profile.getEmail())
                        .fullName(profile.getFullName())
                        .login(profile.getLogin())
                        .idExt(profile.getIdExt())
                        .id(profile.getId())
                        .build())
                .toList();
    }

    public List<UserProfileShortV2DTO> getUsersByIds(List<Integer> userIds) {
        log.info(userIds.toString());
        List<Integer> uniqueUserIds = new ArrayList<>(
                userIds.stream()
                        .filter(Objects::nonNull)
                        .collect(Collectors.toCollection(LinkedHashSet::new)));
        List<UserProfile> userProfile = userProfileRepository.findAllById(uniqueUserIds);
        if (userProfile.size() != uniqueUserIds.size()) {
            Set<Integer> foundIds = userProfile.stream()
                    .map(UserProfile::getId)
                    .collect(Collectors.toSet());
            List<Integer> missingIds = uniqueUserIds.stream()
                    .filter(id -> !foundIds.contains(id))
                    .toList();
            log.warn("Часть переданных id пользователей не найдена в БД, они будут пропущены: {}", missingIds);
        }
        return userProfile.stream()
                .map(profile -> UserProfileShortV2DTO.builder()
                        .email(profile.getEmail())
                        .fullName(profile.getFullName())
                        .id(profile.getId())
                        .login(profile.getLogin())
                        .idExt(profile.getIdExt())
                        .build())
                .collect(Collectors.toList());
    }
}
