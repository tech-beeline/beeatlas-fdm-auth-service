package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.domain.UserRoles;
import ru.beeline.fdmauth.dto.PermissionDTO;
import ru.beeline.fdmauth.service.PermissionService;
import ru.beeline.fdmauth.service.RoleService;
import ru.beeline.fdmauth.service.UserProfileService;
import ru.beeline.fdmauth.dto.PermissionDTO;
import ru.beeline.fdmauth.dto.RoleDTO;
import ru.beeline.fdmauth.dto.UserProfileDTO;

import java.util.*;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/admin/v1/profiles")
@Api(value = "Profile API", tags = "Profile")
public class UserProfileController {

    private Logger logger = LoggerFactory.getLogger(UserProfileController.class);

    @Autowired
    private UserProfileService userProfileService;

    @Autowired
    private RoleService roleService;

    @Autowired
    private PermissionService permissionService;

    @GetMapping
    @ResponseBody
    @ApiOperation(value = "Получение профилей пользователей")
    public ResponseEntity<List<UserProfileDTO>> getAllProfiles(@RequestHeader("Authorization") String bearerToken) {
        List<UserProfileDTO> users = UserProfileDTO.convert(userProfileService.getAllUsers());
        return (users != null) ? ResponseEntity.ok(users) : ResponseEntity.ok(new ArrayList<>());
    }

    @PostMapping
    @ResponseBody
    @ApiOperation(value = "Создание профиля пользователя")
    public ResponseEntity<UserProfileDTO> createUserProfile(@RequestHeader("Authorization") String bearerToken,
                                                           @RequestBody UserProfileDTO userProfileVM) {
        return ResponseEntity.ok(userProfileService.createUserProfileVM(userProfileVM));
    }

    @PutMapping("/{id}")
    @ResponseBody
    @ApiOperation(value = "Изменение профиля пользователя")
    public ResponseEntity<UserProfileDTO> editUserProfile(@RequestHeader("Authorization") String bearerToken,
                                                         @PathVariable Long id,
                                                         @RequestBody UserProfileDTO userProfileVM) {
        Optional<UserProfile> userProfileOpt = userProfileService.findProfileById(id);
        if(userProfileOpt.isPresent()) {
            UserProfile userProfile = userProfileOpt.get();
            UserProfileDTO vm = userProfileService.editUserProfile(userProfile, userProfileVM);
            if(vm != null) return ResponseEntity.ok(vm);
        }
        logger.error(String.format("404 Пользователь c id = %d не найден", id));
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/find")
    @ResponseBody
    @ApiOperation(value = "Поиск профилей пользователей")
    public ResponseEntity<List<UserProfileDTO>> findUserProfiles(@RequestHeader("Authorization") String bearerToken,
                                                                @RequestParam(value = "text", required = true) String text,
                                                                @RequestParam("filter") String filter) {
        List<UserProfileDTO> users = UserProfileDTO.convert(userProfileService.getAllUsers());
        return (users != null) ? ResponseEntity.ok(users) : ResponseEntity.ok(new ArrayList<>());
    }


    @GetMapping("/{login}")
    @ResponseBody
    @ApiOperation(value = "Получение профиля")
    public ResponseEntity<UserProfileDTO> getUserProfileByLogin(@RequestHeader("Authorization") String bearerToken,
                                                               @PathVariable String login) {
        UserProfile userProfile = userProfileService.findProfileByLogin(login);

        if(userProfile != null) {
            return ResponseEntity.ok(new UserProfileDTO(userProfile));
        } else {
            logger.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/{login}/roles")
    @ResponseBody
    @ApiOperation(value = "Получение ролей профиля")
    public ResponseEntity<List<RoleDTO>> getUserProfileRoles(@RequestHeader("Authorization") String bearerToken,
                                                            @PathVariable String login) {
        UserProfile userProfile = userProfileService.findProfileByLogin(login);
        if(userProfile == null) {
            logger.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(RoleDTO.convert(userProfile.getUserRoles()));
    }

    @GetMapping("/{login}/permissions")
    @ResponseBody
    @ApiOperation(value = "Получение разрешений профиля")
    public ResponseEntity<Set<PermissionDTO>> getUserProfilePermissions(@RequestHeader("Authorization") String bearerToken,
                                                                       @PathVariable String login) {
        UserProfile userProfile = userProfileService.findProfileByLogin(login);
        if(userProfile == null) {
            logger.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
        Set<Permission> rPermissions = new HashSet<>();
        for(UserRoles role : userProfile.getUserRoles()){
            List<Permission> rolePermissions = roleService.getPermissions(role.getId());
            if(!rolePermissions.isEmpty()) rPermissions.addAll(rolePermissions);
        }
        Set<PermissionDTO> userPermissions = permissionService.getUserPermissions(rPermissions);
        return ResponseEntity.ok(userPermissions);
    }


    @PutMapping("/{login}/roles")
    @ResponseBody
    @ApiOperation(value = "Установка ролей профиля")
    public ResponseEntity<UserProfileDTO> setUserProfileRoles(@RequestHeader("Authorization") String bearerToken,
                                                             @PathVariable String login,
                                                             @RequestBody List<RoleDTO> roles) {
        UserProfile userProfile = userProfileService.findProfileByLogin(login);
        if(userProfile != null) {
            return ResponseEntity.ok(userProfileService.setRoles(userProfile, roles));
        } else {
            logger.error(String.format("404 Пользователь c login '%s' не найден", login));
            return ResponseEntity.notFound().build();
        }
    }
}
