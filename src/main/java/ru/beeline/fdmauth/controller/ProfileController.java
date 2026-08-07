/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.beeline.fdmauth.annotation.ApiErrorCodes;
import ru.beeline.fdmauth.dto.EmailResponseDTO;
import ru.beeline.fdmauth.service.UserProfileService;

@RestController
@RequestMapping("/api/v1/profiles")
@Tag(name = "Профили", description = "Получение контактных данных профиля пользователя")
public class ProfileController {

    @Autowired
    private UserProfileService userProfileService;

    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/{userId}/email", produces = "application/json")
    @Operation(summary = "Получение email пользователя по id")
    public EmailResponseDTO getEmailById(@PathVariable Integer userId) {
        return new EmailResponseDTO(userProfileService.getEmailById(userId));
    }
}
