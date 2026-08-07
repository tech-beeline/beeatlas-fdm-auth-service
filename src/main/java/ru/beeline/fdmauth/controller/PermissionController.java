/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.annotation.ApiErrorCodes;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.service.PermissionService;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/admin/v1/permissions")
@Tag(name = "Разрешения", description = "Справочник разрешений системы")
public class PermissionController {

    @Autowired
    private PermissionService permissionService;

    @ApiErrorCodes({400, 500})
    @GetMapping(produces = "application/json")
    @Operation(summary = "Получение справочника разрешений")
    public List<Permission> getAllPermissions() {
        List<Permission> permissions = permissionService.getAllPermissions();
        return (permissions != null) ? permissions : new ArrayList<>();
    }
}
