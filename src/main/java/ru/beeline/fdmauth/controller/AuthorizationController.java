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
import ru.beeline.fdmauth.dto.rbac.AuthorizeRequestDTO;
import ru.beeline.fdmauth.dto.rbac.AuthorizeResponseDTO;
import ru.beeline.fdmauth.service.rbac.AuthorizationService;

@RestController
@RequestMapping("/api/v1")
@Tag(name = "Авторизация", description = "Проверка прав доступа к маршрутам. Вызывается API Gateway")
@Slf4j
public class AuthorizationController {

    @Autowired
    private AuthorizationService authorizationService;

    @ApiErrorCodes({400, 500})
    @PostMapping("/authorize")
    @Operation(summary = "Проверка доступа",
            description = "Проверяет, разрешён ли доступ пользователя к запрашиваемому маршруту. Вызывается API Gateway")
    public ResponseEntity<AuthorizeResponseDTO> authorize(@RequestBody AuthorizeRequestDTO request) {
        AuthorizeResponseDTO response = authorizationService.authorize(request);
        return ResponseEntity.ok(response);
    }
}
