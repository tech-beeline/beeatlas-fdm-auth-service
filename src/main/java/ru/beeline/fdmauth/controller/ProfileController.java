package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.beeline.fdmauth.service.UserService;
import ru.beeline.fdmlib.dto.auth.EmailResponseDTO;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/v1/profiles")
@Api(value = "BeeWorks API", tags = "BeeWorks")
public class ProfileController {

    @Autowired
    private UserService userService;

    @GetMapping(value = "/{userId}/email", produces = "application/json")
    @ApiOperation(value = "Получение email пользователя по id", response = EmailResponseDTO.class)
    public EmailResponseDTO getEmailById(@PathVariable Long userId) {
        return new EmailResponseDTO(userService.getEmailById(userId));
    }
}
