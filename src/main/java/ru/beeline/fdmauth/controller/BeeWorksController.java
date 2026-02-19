/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.dto.bw.EmployeeProductsDTO;
import ru.beeline.fdmauth.client.BWEmployeeClient;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/bw")
@Api(value = "BeeWorks API", tags = "BeeWorks")
public class BeeWorksController {

    @Autowired
    private BWEmployeeClient bwEmployeeClient;

    @GetMapping(value = "/products/{login}", produces = "application/json")
    @ApiOperation(value = "Получение списка продуктов из BeeWorks по логину пользователя", response = EmployeeProductsDTO.class)
    public EmployeeProductsDTO getEmployeeProducts(@PathVariable String login) {
        return bwEmployeeClient.getEmployeeInfo(login);
    }
}
