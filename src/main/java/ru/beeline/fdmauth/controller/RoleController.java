/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.annotation.ApiErrorCodes;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.domain.Role;
import ru.beeline.fdmauth.dto.role.RoleCreateDTO;
import ru.beeline.fdmauth.dto.role.RoleDTO;
import ru.beeline.fdmauth.service.RoleService;
import ru.beeline.fdmauth.dto.PermissionDTO;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/admin/v1/roles")
@Tag(name = "Роли", description = "Справочник ролей и управление разрешениями ролей")
@Slf4j
public class RoleController {

    @Autowired
    private RoleService roleService;

    @ApiErrorCodes({400, 500})
    @GetMapping(produces = "application/json")
    @ResponseBody
    @Operation(summary = "Получение коллекции ролей пользователей ФДМ")
    public List<Role> getAllRoles() {
        return roleService.getAllNotDeletedRoles();
    }

    @ApiErrorCodes({400, 403, 500})
    @PostMapping(produces = "application/json")
    @ResponseBody
    @Operation(summary = "Создание новой роли в справочнике ролей")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Новая роль была успешно создана"),
            @ApiResponse(responseCode = "403", description = "Недостаточно прав"),
            @ApiResponse(responseCode = "400", description = "Роль с таким именем уже существует")
    })
    public ResponseEntity<Role> createRole(@RequestBody RoleCreateDTO role) {
        return ResponseEntity.ok(roleService.createNewRole(role));
    }


    @ApiErrorCodes({403, 404, 409, 500})
    @PatchMapping(produces = "application/json")
    @ResponseBody
    @Operation(summary = "Изменение роли в справочнике ролей")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Роль была успешно изменена"),
            @ApiResponse(responseCode = "409", description = "Имя роли совпадает с именем другой роли"),
            @ApiResponse(responseCode = "403", description = "Недостаточно прав"),
            @ApiResponse(responseCode = "404", description = "Роль c таким id не найдена")
    })
    public ResponseEntity<Role> updateRole(@RequestBody RoleDTO role) {
        return ResponseEntity.ok(roleService.updateRole(role.getId(), role));
    }

    @ApiErrorCodes({403, 404, 500})
    @GetMapping(value = "/{id}", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Получение роли")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Успешно"),
            @ApiResponse(responseCode = "403", description = "Недостаточно прав"),
            @ApiResponse(responseCode = "404", description = "Роль c таким id не найдена")
    })
    public ResponseEntity<Role> getRole(@PathVariable Long id) {
        Optional<Role> currentRoleOpt = roleService.findRole(id);
        if(currentRoleOpt.isPresent()) {
            return ResponseEntity.ok(currentRoleOpt.get());
        } else {
            String errText = String.format("404 Роль c id='%d' не найдена", id);
            log.error(errText);
            return ResponseEntity.notFound().build();
        }
    }

    @ApiErrorCodes({403, 404, 500})
    @DeleteMapping(value = "/{id}", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Удаление роли (статус меняется на DELETED)")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Успешно"),
            @ApiResponse(responseCode = "403", description = "Недостаточно прав"),
            @ApiResponse(responseCode = "404", description = "Роль c таким id не найдена")
    })
    public ResponseEntity deleteRole(@PathVariable Long id) {
        {
            Optional<Role> currentRoleOpt = roleService.findRole(id);
            if (currentRoleOpt.isPresent()) {
                Role currentRole = currentRoleOpt.get();
                if(currentRole.isDefault()) {
                    String errText = String.format("Удаляемая роль '%s' является дефолтной", currentRole.getName());
                    log.error("400 " + errText);
                    return ResponseEntity.badRequest().body(errText);
                } else {
                    roleService.delete(currentRole);
                    return ResponseEntity.ok().build();
                }
            } else {
                String errText = String.format("404 Роль c id='%d' не найдена", id);
                log.error(errText);
                return ResponseEntity.notFound().build();
            }
        }
    }

    @ApiErrorCodes({403, 404, 500})
    @GetMapping(value = "/{id}/permissions", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Получение разрешений для роли")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Успешно"),
            @ApiResponse(responseCode = "403", description = "Недостаточно прав"),
            @ApiResponse(responseCode = "404", description = "Роль c таким id не найдена")
    })
    public ResponseEntity<List<PermissionDTO>> getRolePermissions(@PathVariable Long id) {
        Optional<Role> currentRoleOpt = roleService.findRole(id);
        if(currentRoleOpt.isPresent()) {
            return ResponseEntity.ok(roleService.getPermissionsWithStatus(id));
        } else {
            String errText = String.format("404 Роль c id='%d' не найдена", id);
            log.error(errText);
            return ResponseEntity.notFound().build();
        }
    }

    @ApiErrorCodes({400, 403, 404, 500})
    @PutMapping(value = "/{id}/permissions", produces = "application/json")
    @ResponseBody
    @Operation(summary = "Сохранение разрешений для роли")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Успешно"),
            @ApiResponse(responseCode = "400", description = "Недостаточно прав"),
            @ApiResponse(responseCode = "403", description = "Недостаточно прав"),
            @ApiResponse(responseCode = "404", description = "Роль c таким id не найдена")
    })
    public ResponseEntity saveRolePermissions(@PathVariable Long id, @RequestBody List<Permission> permissions) {
        if (id == 1 || id == 2) {
            String roleName = id == 1 ? "Сотрудник" : "Администратор";

            String errText = String.format("Роль '%s' является дефолтной, нельзя менять разрешения роли", roleName);
            log.error("400 " + errText);
            return ResponseEntity.badRequest().body(errText);
        }

        Optional<Role> currentRoleOpt = roleService.findRole(id);
        if(currentRoleOpt.isPresent()) {
            Role role = currentRoleOpt.get();
            roleService.saveRolePermissions(role, permissions);
            return ResponseEntity.ok(roleService.getPermissions(role.getId()));
        } else {
            String errText = String.format("404 Роль c id='%d' не найдена", id);
            log.error(errText);
            return ResponseEntity.notFound().build();
        }
    }

}
