/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Tag(name = "Приложение", description = "Служебная информация о сервисе: имя и версия")
public class ApplicationController {

    @Value("${app.version}")
    private String appVersion;

    @Value("${app.name}")
    private String appName;


    @GetMapping("/")
    @Operation(summary = "Приветствие", description = "Возвращает имя и версию запущенного сервиса")
    public String getData() {
        return "Welcome " + appName + " " + appVersion;
    }

}
