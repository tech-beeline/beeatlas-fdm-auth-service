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
import ru.beeline.fdmauth.dto.CreateUserRequestDTO;
import ru.beeline.fdmauth.dto.CreateUserResponseDTO;
import ru.beeline.fdmauth.dto.UserProfileDTO;
import ru.beeline.fdmauth.dto.UserProfileShortV2DTO;
import ru.beeline.fdmauth.dto.myprofile.MyProfileUserSearchResultDTO;
import ru.beeline.fdmauth.service.MyProfileSearchService;
import ru.beeline.fdmauth.service.UserProfileService;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@Tag(name = "Пользователи", description = "Публичное API для работы с профилями пользователей ФДМ")
public class UserController {

    @Autowired
    private UserProfileService userProfileService;

    @Autowired
    private MyProfileSearchService myProfileSearchService;

    @ApiErrorCodes({400, 404, 500})
    @GetMapping(value = "/user/{id}", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Получение профиля по id")
    public ResponseEntity<UserProfileDTO> getUserProfileById(@PathVariable Integer id) {
        return ResponseEntity.ok(userProfileService.findProfileById(id));
    }

    @ApiErrorCodes({400, 404, 500})
    @ResponseBody
    @Operation(summary = "Получение профилей по списку id")
    @GetMapping(value = "/user", produces = "application/json")
    public ResponseEntity<List<UserProfileShortV2DTO>> getUserProfileByIdIn(@RequestParam List<Integer> ids) {
        return ResponseEntity.ok(userProfileService.findProfileByIdIn(ids));
    }

    @ApiErrorCodes({400, 404, 500})
    @GetMapping(value = "/user/role/{aliasRole}", produces = "application/json")
    @Operation(summary = "Получение всех пользователей с определенной ролью")
    public ResponseEntity<List<UserProfileShortV2DTO>> checkUserExistence(@PathVariable String aliasRole) {
        return ResponseEntity.ok(userProfileService.getProfilesByRoleAlias(aliasRole));
    }

    @ApiErrorCodes({400, 404, 500})
    @GetMapping(value = "/users", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Получить список всех пользователей ФДМ")
    public ResponseEntity<List<UserProfileShortV2DTO>> getAllUserProfileFdm() {
        return ResponseEntity.ok(userProfileService.getAllUserProfileFdmV2());
    }

    @ApiErrorCodes({400, 500})
    @PostMapping(value = "/users", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Создание пользователей (для owners)")
    public ResponseEntity<?> createUsers(@RequestBody List<CreateUserRequestDTO> users) {
        try {
            List<CreateUserResponseDTO> result = userProfileService.createUsers(users);
            return ResponseEntity.ok(result);
        } catch (IllegalArgumentException e) {
            if ("Не переданы обязательные параметры".equals(e.getMessage())) {
                return ResponseEntity.badRequest().body(Map.of("errorMessage", e.getMessage()));
            }
            return ResponseEntity.badRequest().body(Map.of("errorMessage", "Не переданы обязательные параметры"));
        }
    }

    @ApiErrorCodes({404, 500})
    @GetMapping(value = "/users/myprofile", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Поиск пользователей в MyProfile с обогащением beeAtlas")
    public ResponseEntity<List<MyProfileUserSearchResultDTO>> searchUsersInMyProfile(@RequestParam(required = false) String search,
                                                                                     @RequestParam(name = "employee_number", required = false) Integer employeeNumber) {
        return ResponseEntity.ok(myProfileSearchService.search(search, employeeNumber));
    }

    @ApiErrorCodes({404, 500})
    @PostMapping(value = "/user/list", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Поиск профилей пользователей")
    public ResponseEntity<List<UserProfileShortV2DTO>> findUserProfiles(@RequestBody List<Integer> userIds) {
        return ResponseEntity.ok(userProfileService.getUsersByIds(userIds));
    }
}
