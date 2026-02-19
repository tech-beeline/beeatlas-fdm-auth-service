/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.beeline.fdmauth.dto.EmailResponseDTO;
import ru.beeline.fdmauth.service.UserProfileService;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/v1/profiles")
@Api(value = "BeeWorks API", tags = "BeeWorks")
public class ProfileController {

    @Autowired
    private UserProfileService userProfileService;

    @GetMapping(value = "/{userId}/email", produces = "application/json")
    @ApiOperation(value = "Получение email пользователя по id", response = EmailResponseDTO.class)
    public EmailResponseDTO getEmailById(@PathVariable Integer userId) {
        return new EmailResponseDTO(userProfileService.getEmailById(userId));
    }
}
