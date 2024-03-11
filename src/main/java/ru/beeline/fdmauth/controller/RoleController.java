package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiResponse;
import io.swagger.annotations.ApiResponses;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.aspect.AccessControl;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.domain.Role;
import ru.beeline.fdmauth.dto.role.RoleCreateDTO;
import ru.beeline.fdmauth.dto.role.RoleDTO;
import ru.beeline.fdmauth.service.RoleService;
import ru.beeline.fdmauth.dto.PermissionDTO;
import java.util.List;
import java.util.Optional;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/admin/v1/roles")
@Api(value = "Role API", tags = "Role")
@Slf4j
public class RoleController {

    @Autowired
    private RoleService roleService;

    @AccessControl
    @GetMapping
    @ResponseBody
    @ApiOperation(value = "Получение коллекции ролей пользователей ФДМ", response = List.class)
    public List<Role> getAllRoles() {
        return roleService.getAllNotDeletedRoles();
    }

    @AccessControl
    @PostMapping
    @ResponseBody
    @ApiOperation(value = "Создание новой роли в справочнике ролей", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Новая роль была успешно создана"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 400, message = "Роль с таким именем уже существует")
    })
    public ResponseEntity<Role> createRole(@RequestBody RoleCreateDTO role) {
        return ResponseEntity.ok(roleService.createNewRole(role));
    }


    @AccessControl
    @PatchMapping
    @ResponseBody
    @ApiOperation(value = "Изменение роли в справочнике ролей", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Роль была успешно изменена"),
            @ApiResponse(code = 409, message = "Имя роли совпадает с именем другой роли"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 404, message = "Роль c таким id не найдена")
    })
    public ResponseEntity<Role> updateRole(@RequestBody RoleDTO role) {
        return ResponseEntity.ok(roleService.updateRole(role.getId(), role));
    }

    @AccessControl
    @GetMapping("/{id}")
    @ResponseBody
    @ApiOperation(value = "Получение роли", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Успешно"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 404, message = "Роль c таким id не найдена")
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

    @AccessControl
    @DeleteMapping("/{id}")
    @ResponseBody
    @ApiOperation(value = "Удаление роли (статус меняется на DELETED)", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Успешно"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 404, message = "Роль c таким id не найдена")
    })
    public ResponseEntity deleteRole(@PathVariable Long id) {
        if (id >= 1 && id <= 8) {
            String roleName = Role.RoleType.getNameById(id.intValue()-1);
            String errText = String.format("Удаляемая роль '%s' является дефолтной", roleName);
            log.error("400 " + errText);
            return ResponseEntity.badRequest().body(errText);
        }
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


    @AccessControl
    @GetMapping("/{id}/permissions")
    @ResponseBody
    @ApiOperation(value = "Получение разрешений для роли", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Успешно"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 404, message = "Роль c таким id не найдена")
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


    @AccessControl
    @PutMapping("/{id}/permissions")
    @ResponseBody
    @ApiOperation(value = "Сохранение разрешений для роли", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Успешно"),
            @ApiResponse(code = 400, message = "Недостаточно прав"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 404, message = "Роль c таким id не найдена")
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
