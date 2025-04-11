package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.aspect.AccessControl;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.domain.UserRoles;
import ru.beeline.fdmauth.dto.PermissionDTO;
import ru.beeline.fdmauth.dto.UserProfileDTO;
import ru.beeline.fdmauth.dto.role.RoleInfoDTO;
import ru.beeline.fdmauth.service.PermissionService;
import ru.beeline.fdmauth.service.RoleService;
import ru.beeline.fdmauth.service.UserService;
import ru.beeline.fdmlib.dto.auth.UserInfoDTO;
import ru.beeline.fdmlib.dto.auth.UserProfileShortDTO;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@Slf4j
@RestController
@RequestMapping("/api")
@Api(value = "User API", tags = "User")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private RoleService roleService;

    @Autowired
    private PermissionService permissionService;


    @AccessControl
    @GetMapping(produces = "application/json")
    @ResponseBody
    @ApiOperation(value = "Получение профилей пользователей")
    public ResponseEntity<List<UserProfileDTO>> getAllProfiles() {
        List<UserProfileDTO> users = UserProfileDTO.convert(userService.getAllUsers());
        return (users != null) ? ResponseEntity.ok(users) : ResponseEntity.ok(new ArrayList<>());
    }


    @AccessControl
    @GetMapping(value = "/admin/v1/user/find", produces = "application/json")
    @ResponseBody
    @ApiOperation(value = "Поиск профилей пользователей")
    public ResponseEntity<List<UserProfileDTO>> findUserProfiles(@RequestParam(value = "text", required = true) String text,
                                                                 @RequestParam("filter") String filter) {
        List<UserProfileDTO> users = UserProfileDTO.convert(userService.getAllUsers());
        return (users != null) ? ResponseEntity.ok(users) : ResponseEntity.ok(new ArrayList<>());
    }


    @AccessControl
    @GetMapping(value = "/admin/v1/user/{login}", produces = "application/json")
    @ResponseBody
    @ApiOperation(value = "Получение профиля")
    public ResponseEntity<UserProfileDTO> getUserProfileByLogin(@PathVariable String login) {
        UserProfile userProfile = userService.findProfileByLogin(login);

        if (userProfile != null) {
            return ResponseEntity.ok(new UserProfileDTO(userProfile));
        } else {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping(value = "/admin/v1/user/{login}/roles", produces = "application/json")
    @ResponseBody
    @ApiOperation(value = "Получение ролей профиля")
    public ResponseEntity<List<RoleInfoDTO>> getUserProfileRoles(@PathVariable String login) {
        UserProfile userProfile = userService.findProfileByLogin(login);
        if (userProfile == null) {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(RoleInfoDTO.convert(userProfile.getUserRoles()));
    }

    @AccessControl
    @GetMapping(value = "/admin/v1/user/{login}/permissions", produces = "application/json")
    @ResponseBody
    @ApiOperation(value = "Получение разрешений профиля")
    public ResponseEntity<Set<PermissionDTO>> getUserProfilePermissions(@PathVariable String login) {
        UserProfile userProfile = userService.findProfileByLogin(login);
        if (userProfile == null) {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
        Set<Permission> rPermissions = new HashSet<>();
        for (UserRoles role : userProfile.getUserRoles()) {
            List<Permission> rolePermissions = roleService.getPermissions(role.getId());
            if (!rolePermissions.isEmpty()) rPermissions.addAll(rolePermissions);
        }
        Set<PermissionDTO> permissions = permissionService.getUserPermissions(rPermissions);
        return ResponseEntity.ok(permissions);
    }


    @AccessControl
    @PutMapping(value = "/admin/v1/user/{login}/roles", produces = "application/json")
    @ResponseBody
    @ApiOperation(value = "Установка ролей профиля")
    public ResponseEntity<UserProfileDTO> setUserProfileRoles(@PathVariable String login, @RequestBody List<RoleInfoDTO> roles) {
        UserProfile userProfile = userService.findProfileByLogin(login);
        if (userProfile != null) {
            return ResponseEntity.ok(userService.setRoles(userProfile, roles));
        } else {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
    }


    @GetMapping(value = "/admin/v1/user/{id}/existence", produces = "application/json")
    @ApiOperation(value = "Проверка существования пользователя", response = Boolean.class)
    public ResponseEntity<Boolean> checkUserExistence(@PathVariable Long id) {
        return ResponseEntity.ok(userService.checkProductExistenceById(id));
    }


    @GetMapping(value = "/api/v1/user/role/{aliasRole}", produces = "application/json")
    @ApiOperation(value = "Получение всех пользователей с определенной ролью", response = Boolean.class)
    public ResponseEntity<List<UserProfileShortDTO>> checkUserExistence(@PathVariable String aliasRole) {
        return ResponseEntity.ok(userService.getProfilesByRoleAlias(aliasRole));
    }


    @GetMapping(value = "/admin/v1/user/{login}/info", produces = "application/json")
    @ApiOperation(value = "Получение информации о пользователе", response = UserInfoDTO.class)
    public ResponseEntity<UserInfoDTO> getUserInfo(@PathVariable String login,
                                                   @RequestParam String email,
                                                   @RequestParam String fullName,
                                                   @RequestParam String idExt
    ) {
        return ResponseEntity.ok(userService.getUserInfo(login, email, fullName, idExt));
    }
}
