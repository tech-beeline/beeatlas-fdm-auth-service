package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.aspect.AdminAccessControl;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.service.PermissionService;
import java.util.ArrayList;
import java.util.List;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/admin/v1/permissions")
@Api(value = "Permission API", tags = "Permission")
public class PermissionController {

    @Autowired
    private PermissionService permissionService;


    @AdminAccessControl
    @GetMapping
    @ApiOperation(value = "Получение справочника разрешений", response = List.class)
    public List<Permission> getAllPermissions(@RequestHeader(value = "USER_ID", required = false) Long userId,
                                              @RequestHeader(value = "USER_PRODUCTS_IDS", required = false) long[] userProductIds,
                                              @RequestHeader(value = "USER_ROLES", required = false) String[] userRoles,
                                              @RequestHeader(value = "USER_PERMISSION", required = false) String[] userPermissions) {
        List<Permission> permissions = permissionService.getAllPermissions();
        return (permissions != null) ? permissions : new ArrayList<>();
    }
}
