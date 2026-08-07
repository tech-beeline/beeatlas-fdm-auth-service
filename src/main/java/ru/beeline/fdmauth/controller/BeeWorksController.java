/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.annotation.ApiErrorCodes;
import ru.beeline.fdmauth.dto.bw.EmployeeProductsDTO;
import ru.beeline.fdmauth.client.BWEmployeeClient;

@RestController
@RequestMapping("/api/bw")
@Tag(name = "BeeWorks", description = "Интеграция со справочником BeeWorks: продукты сотрудников")
public class BeeWorksController {

    @Autowired
    private BWEmployeeClient bwEmployeeClient;

    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/products/{login}", produces = "application/json")
    @Operation(summary = "Получение списка продуктов из BeeWorks по логину пользователя")
    public EmployeeProductsDTO getEmployeeProducts(@PathVariable String login) {
        return bwEmployeeClient.getEmployeeInfo(login);
    }
}
