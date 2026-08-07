/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.annotation.ApiErrorCodes;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.domain.UserRoles;
import ru.beeline.fdmauth.dto.PermissionDTO;
import ru.beeline.fdmauth.dto.UserInfoDTO;
import ru.beeline.fdmauth.dto.UserProfileDTO;
import ru.beeline.fdmauth.dto.role.RoleInfoDTO;
import ru.beeline.fdmauth.service.PermissionService;
import ru.beeline.fdmauth.service.RoleService;
import ru.beeline.fdmauth.service.UserProfileService;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Slf4j
@RestController
@RequestMapping("/api/admin/v1/user")
@Tag(name = "Администрирование пользователей", description = "Управление профилями, ролями и разрешениями пользователей")
public class AdminUserController {

    @Autowired
    private UserProfileService userProfileService;

    @Autowired
    private RoleService roleService;

    @Autowired
    private PermissionService permissionService;


    @ApiErrorCodes({400, 500})
    @GetMapping
    @ResponseBody
    @Operation(summary = "Получение профилей пользователей")
    public ResponseEntity<List<UserProfileDTO>> getAllProfiles() {
        List<UserProfileDTO> users = userProfileService.getAllUsersAsDTO();
        return (users != null) ? ResponseEntity.ok(users) : ResponseEntity.ok(new ArrayList<>());
    }


    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/find", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Поиск профилей пользователей")
    public ResponseEntity<List<UserProfileDTO>> findUserProfiles(@RequestParam(value = "text", required = true) String text,
                                                                 @RequestParam("filter") String filter) {
        List<UserProfileDTO> users = userProfileService.getAllUsersAsDTO();
        return (users != null) ? ResponseEntity.ok(users) : ResponseEntity.ok(new ArrayList<>());
    }


    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/{login}", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Получение профиля")
    public ResponseEntity<UserProfileDTO> getUserProfileByLogin(@PathVariable String login) {
        UserProfileDTO userProfileDTO = userProfileService.findProfileByLoginAsDTO(login);

        if (userProfileDTO != null) {
            return ResponseEntity.ok(userProfileDTO);
        } else {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
    }

    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/{login}/roles", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Получение ролей профиля")
    public ResponseEntity<List<RoleInfoDTO>> getUserProfileRoles(@PathVariable String login) {
        UserProfile userProfile = userProfileService.findProfileByLogin(login);
        if (userProfile == null) {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
        List<UserRoles> userRoles = userProfileService.getUserRolesWithPermissions(userProfile);
        return ResponseEntity.ok(RoleInfoDTO.convert(userRoles));
    }

    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/{login}/permissions", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Получение разрешений профиля")
    public ResponseEntity<Set<PermissionDTO>> getUserProfilePermissions(@PathVariable String login) {
        UserProfile userProfile = userProfileService.findProfileByLogin(login);
        if (userProfile == null) {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
        List<UserRoles> userRoles = userProfileService.getUserRolesWithPermissions(userProfile);
        Set<Permission> rPermissions = new HashSet<>();
        for (UserRoles role : userRoles) {
            List<Permission> rolePermissions = roleService.getPermissions(role.getId());
            if (!rolePermissions.isEmpty())
                rPermissions.addAll(rolePermissions);
        }
        Set<PermissionDTO> permissions = permissionService.getUserPermissions(rPermissions);
        return ResponseEntity.ok(permissions);
    }

    @ApiErrorCodes({400, 500})
    @PutMapping(value = "/{login}/roles", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Установка ролей профиля")
    public ResponseEntity<UserProfileDTO> setUserProfileRoles(@PathVariable String login,
                                                              @RequestBody List<RoleInfoDTO> roles) {
        UserProfile userProfile = userProfileService.findProfileByLogin(login);
        if (userProfile != null) {
            return ResponseEntity.ok(userProfileService.setRoles(userProfile, roles));
        } else {
            log.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
    }

    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/{id}/existence", produces = "application/json")
    @Operation(summary = "Проверка существования пользователя")
    public ResponseEntity<Boolean> checkUserExistence(@PathVariable Integer id) {
        return ResponseEntity.ok(userProfileService.checkProductExistenceById(id));
    }

    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/{id}/user-info", produces = "application/json")
    @Operation(summary = "Получение информации о пользователе по id")
    public ResponseEntity<UserInfoDTO> getUserInfoById(@PathVariable Integer id) {
        return ResponseEntity.ok(userProfileService.getUserInfoById(id));
    }

    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/{login}/info", produces = "application/json")
    @Operation(summary = "Получение информации о пользователе")
    public ResponseEntity<UserInfoDTO> getUserInfo(@PathVariable String login,
                                                   @RequestParam String email,
                                                   @RequestParam String fullName,
                                                   @RequestParam String idExt) {
        return ResponseEntity.ok(userProfileService.getUserInfo(login, email, fullName, idExt));
    }

}
