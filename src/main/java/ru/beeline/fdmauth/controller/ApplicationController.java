package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Api(value = "Application API", tags = "Application")
public class ApplicationController {

    @Value("${app.version}")
    private String appVersion;

    @Value("${app.name}")
    private String appName;


    @GetMapping("/")
    public String getData() {
        return "Welcome " + appName + " " + appVersion;
    }

}
