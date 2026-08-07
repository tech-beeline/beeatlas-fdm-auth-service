/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.beeline.fdmauth.annotation.ApiErrorCodes;
import ru.beeline.fdmauth.client.BWEmployeeClient;

@RestController
@Tag(name = "Конфигурация", description = "Служебные операции конфигурации и интеграций")
public class ConfigurationController {


    @Autowired
    private BWEmployeeClient bwEmployeeClient;

    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/api/runtime/v1/mapic/token", produces = "application/json")
    @Operation(summary = "Обновление и получение токена MAPIC")
    public String getEmployeeProducts() {
        bwEmployeeClient.updateAccessToken();
        return bwEmployeeClient.getAccessToken();
    }
}
