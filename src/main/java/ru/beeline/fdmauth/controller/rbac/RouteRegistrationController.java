/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller.rbac;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.dto.rbac.RouteRegistrationDTO;
import ru.beeline.fdmauth.service.rbac.RbacAdminService;

import java.util.List;

@RestController
@RequestMapping("/api/v1/rbac")
public class RouteRegistrationController {

    @Autowired
    private RbacAdminService rbacAdminService;

    @PostMapping("/routes/register")
    public ResponseEntity<Void> register(@RequestBody List<RouteRegistrationDTO> routes) {
        rbacAdminService.registerRoutes(routes);
        return ResponseEntity.ok().build();
    }
}
