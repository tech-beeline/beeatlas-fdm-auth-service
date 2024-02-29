package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.aspect.AdminAccessControl;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.domain.UserRoles;
import ru.beeline.fdmauth.dto.PermissionDTO;
import ru.beeline.fdmauth.dto.UserInfoDTO;
import ru.beeline.fdmauth.service.PermissionService;
import ru.beeline.fdmauth.service.RoleService;
import ru.beeline.fdmauth.service.UserService;
import ru.beeline.fdmauth.dto.role.RoleInfoDTO;
import ru.beeline.fdmauth.dto.UserProfileDTO;
import java.util.*;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@Slf4j
@RestController
@RequestMapping("/api/admin/v1/user")
@Api(value = "User API", tags = "User")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private RoleService roleService;

    @Autowired
    private PermissionService permissionService;


    @AdminAccessControl
    @GetMapping
    @ResponseBody
    @ApiOperation(value = "Получение профилей пользователей")
    public ResponseEntity<List<UserProfileDTO>> getAllProfiles(@RequestHeader(value = "USER_ID", required = false) Long userId,
                                                               @RequestHeader(value = "USER_PRODUCTS_IDS", required = false) long[] userProductIds,
                                                               @RequestHeader(value = "USER_ROLES", required = false) String[] userRoles,
                                                               @RequestHeader(value = "USER_PERMISSION", required = false) String[] userPermissions) {
        List<UserProfileDTO> users = UserProfileDTO.convert(userService.getAllUsers());
        return (users != null) ? ResponseEntity.ok(users) : ResponseEntity.ok(new ArrayList<>());
    }


    @AdminAccessControl
    @GetMapping("/find")
    @ResponseBody
    @ApiOperation(value = "Поиск профилей пользователей")
    public ResponseEntity<List<UserProfileDTO>> findUserProfiles(@RequestParam(value = "text", required = true) String text,
                                                                 @RequestParam("filter") String filter,
                                                                 @RequestHeader(value = "USER_ID", required = false) Long userId,
                                                                 @RequestHeader(value = "USER_PRODUCTS_IDS", required = false) long[] userProductIds,
                                                                 @RequestHeader(value = "USER_ROLES", required = false) String[] userRoles,
                                                                 @RequestHeader(value = "USER_PERMISSION", required = false) String[] userPermissions) {
        List<UserProfileDTO> users = UserProfileDTO.convert(userService.getAllUsers());
        return (users != null) ? ResponseEntity.ok(users) : ResponseEntity.ok(new ArrayList<>());
    }


    @AdminAccessControl
    @GetMapping("/{login}")
    @ResponseBody
    @ApiOperation(value = "Получение профиля")
    public ResponseEntity<UserProfileDTO> getUserProfileByLogin(@PathVariable String login,
                                                                @RequestHeader(value = "USER_ID", required = false) Long userId,
                                                                @RequestHeader(value = "USER_PRODUCTS_IDS", required = false) long[] userProductIds,
                                                                @RequestHeader(value = "USER_ROLES", required = false) String[] userRoles,
                                                                @RequestHeader(value = "USER_PERMISSION", required = false) String[] userPermissions) {
        UserProfile userProfile = userService.findProfileByLogin(login);

        if(userProfile != null) {
            return ResponseEntity.ok(new UserProfileDTO(userProfile));
        } else {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
    }

    @AdminAccessControl
    @GetMapping("/{login}/roles")
    @ResponseBody
    @ApiOperation(value = "Получение ролей профиля")
    public ResponseEntity<List<RoleInfoDTO>> getUserProfileRoles(@PathVariable String login,
                                                                 @RequestHeader(value = "USER_ID", required = false) Long userId,
                                                                 @RequestHeader(value = "USER_PRODUCTS_IDS", required = false) long[] userProductIds,
                                                                 @RequestHeader(value = "USER_ROLES", required = false) String[] userRoles,
                                                                 @RequestHeader(value = "USER_PERMISSION", required = false) String[] userPermissions) {
        UserProfile userProfile = userService.findProfileByLogin(login);
        if(userProfile == null) {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(RoleInfoDTO.convert(userProfile.getUserRoles()));
    }

    @AdminAccessControl
    @GetMapping("/{login}/permissions")
    @ResponseBody
    @ApiOperation(value = "Получение разрешений профиля")
    public ResponseEntity<Set<PermissionDTO>> getUserProfilePermissions(@PathVariable String login,
                                                                        @RequestHeader(value = "USER_ID", required = false) Long userId,
                                                                        @RequestHeader(value = "USER_PRODUCTS_IDS", required = false) long[] userProductIds,
                                                                        @RequestHeader(value = "USER_ROLES", required = false) String[] userRoles,
                                                                        @RequestHeader(value = "USER_PERMISSION", required = false) String[] userPermissions) {
        UserProfile userProfile = userService.findProfileByLogin(login);
        if(userProfile == null) {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
        Set<Permission> rPermissions = new HashSet<>();
        for(UserRoles role : userProfile.getUserRoles()){
            List<Permission> rolePermissions = roleService.getPermissions(role.getId());
            if(!rolePermissions.isEmpty()) rPermissions.addAll(rolePermissions);
        }
        Set<PermissionDTO> permissions = permissionService.getUserPermissions(rPermissions);
        return ResponseEntity.ok(permissions);
    }


    @AdminAccessControl
    @PutMapping("/{login}/roles")
    @ResponseBody
    @ApiOperation(value = "Установка ролей профиля")
    public ResponseEntity<UserProfileDTO> setUserProfileRoles(@PathVariable String login,
                                                             @RequestBody List<RoleInfoDTO> roles,
                                                              @RequestHeader(value = "USER_ID", required = false) Long userId,
                                                              @RequestHeader(value = "USER_PRODUCTS_IDS", required = false) long[] userProductIds,
                                                              @RequestHeader(value = "USER_ROLES", required = false) String[] userRoles,
                                                              @RequestHeader(value = "USER_PERMISSION", required = false) String[] userPermissions) {
        UserProfile userProfile = userService.findProfileByLogin(login);
        if(userProfile != null) {
            return ResponseEntity.ok(userService.setRoles(userProfile, roles));
        } else {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
    }


    @GetMapping("/{id}/existence")
    @ApiOperation(value = "Проверка существования пользователя", response = Boolean.class)
    public ResponseEntity<Boolean> checkUserExistence(@PathVariable Long id) {
        return ResponseEntity.ok(userService.checkProductExistenceById(id));
    }


    @GetMapping("/{login}/info")
    @ApiOperation(value = "Получение информации о пользователе", response = UserInfoDTO.class)
    public ResponseEntity<UserInfoDTO> getUserInfo(@PathVariable String login,
                                                   @RequestParam String email,
                                                   @RequestParam String fullName,
                                                   @RequestParam String idExt
                                                   ) {
        UserProfile userProfile = userService.findProfileByLogin(login);
        if(userProfile == null) {
            userProfile = userService.createNewUserAndProducts(login, email, fullName, idExt);
            userService.addDefaultRole(userProfile);
            userProfile = userService.findUserById(userProfile.getId());
        } else {
            if(userProfile.getUserProducts() == null || userProfile.getUserProducts().isEmpty()) {
                userService.findAndSaveProducts(userProfile);
            }
        }
        return ResponseEntity.ok(userService.getInfo(userProfile));
    }
}
