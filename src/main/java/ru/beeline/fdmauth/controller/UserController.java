package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.dto.UserProfileDTO;
import ru.beeline.fdmauth.service.UserProfileService;
import ru.beeline.fdmlib.dto.auth.UserProfileShortDTO;

import java.util.List;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@Slf4j
@RestController
@RequestMapping("/api/v1/user")
@Api(value = "User API", tags = "User")
public class UserController {

    @Autowired
    private UserProfileService userProfileService;

    @GetMapping(value = "/{id}", produces = "application/json")
    @ResponseBody
    @ApiOperation(value = "Получение профиля по id")
    public ResponseEntity<UserProfileDTO> getUserProfileById(@PathVariable Integer id) {
        return ResponseEntity.ok(userProfileService.findProfileById(id));
    }

    @GetMapping(value = "/role/{aliasRole}", produces = "application/json")
    @ApiOperation(value = "Получение всех пользователей с определенной ролью", response = Boolean.class)
    public ResponseEntity<List<UserProfileShortDTO>> checkUserExistence(@PathVariable String aliasRole) {
        return ResponseEntity.ok(userProfileService.getProfilesByRoleAlias(aliasRole));
    }

    @PostMapping(value = "/list", produces = "application/json")
    @ResponseBody
    @ApiOperation(value = "Поиск профилей пользователей", response = List.class)
    public ResponseEntity<List<UserProfileShortDTO>> findUserProfiles(@RequestBody List<Integer> userIds) {
        return ResponseEntity.ok(userProfileService.getUsersByIds(userIds));
    }
}
