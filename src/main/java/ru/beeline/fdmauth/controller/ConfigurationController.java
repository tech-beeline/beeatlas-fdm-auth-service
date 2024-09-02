package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.beeline.fdmauth.client.BWEmployeeClient;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@Api(value = "App Configuration API", tags = "Configuration")
public class ConfigurationController {


    @Autowired
    private BWEmployeeClient bwEmployeeClient;

    @GetMapping(value = "/api/runtime/v1/mapic/token", produces = "application/json")
    @ApiOperation(value = "Обновление и получение токена MAPIC", response = String.class)
    public String getEmployeeProducts() {
        bwEmployeeClient.updateAccessToken();
        return bwEmployeeClient.getAccessToken();
    }
}
