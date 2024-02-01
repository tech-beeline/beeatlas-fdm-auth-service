package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiResponse;
import io.swagger.annotations.ApiResponses;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.domain.Role;
import ru.beeline.fdmauth.domain.RolePermission;
import ru.beeline.fdmauth.dto.RoleShortDTO;
import ru.beeline.fdmauth.service.RoleService;
import ru.beeline.fdmauth.dto.PermissionDTO;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/admin/v1/roles")
@Api(value = "Role API", tags = "Role")
public class RoleController {

    private Logger logger = LoggerFactory.getLogger(RoleController.class);

    @Autowired
    private RoleService roleService;

    @GetMapping
    @ResponseBody
    @ApiOperation(value = "Получение коллекции ролей пользователей ФДМ", response = List.class)
    public List<Role> getAllRoles(@RequestHeader("Authorization") String bearerToken) {
        List<Role> roles = roleService.getAllRoles();
        roles.removeIf(Role::isDeleted);
        for (Role role : roles) {
            if (role.getPermissions().isEmpty()) {
                List<RolePermission> rolePermissions = roleService.getRolePermissions(role.getId());
                if (!rolePermissions.isEmpty()) role.setPermissions(rolePermissions);
            }
        }
        return roles;
    }


    @PostMapping
    @ResponseBody
    @ApiOperation(value = "Создание новой роли в справочнике ролей", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Новая роль была успешно создана"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 400, message = "Роль с таким именем уже существует")
    })
    public ResponseEntity createRole(@RequestHeader("Authorization") String bearerToken,
                                     @RequestBody RoleShortDTO role) {
        boolean isExist = roleService.checkNameIsUnique(role.getName());
        if (isExist) {
            String errText = String.format("Конфликт: Роль с именем '%s' уже существует", role.getName());
            logger.error("409 " + errText);
            return ResponseEntity.status(HttpStatus.CONFLICT).body(errText);
        } else {
            //mock
            Role newRole = roleService.createRole(role);
            List<Permission> permissions = new ArrayList<>();
            permissions.add(new Permission(1));
            permissions.add(new Permission(2));
            permissions.add(new Permission(3));
            roleService.saveRolePermissions(newRole, permissions);
            return ResponseEntity.ok(newRole);
        }
    }


    @PatchMapping
    @ResponseBody
    @ApiOperation(value = "Изменение роли в справочнике ролей", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Роль была успешно изменена"),
            @ApiResponse(code = 409, message = "Имя роли совпадает с именем другой роли"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 404, message = "Роль c таким id не найдена")
    })
    public ResponseEntity updateRole(@RequestHeader("Authorization") String bearerToken,
                                     @RequestBody RoleShortDTO role) {
        if (role.getId() != null) {
            Long id = role.getId();
            if (id >= 1 && id <= 8) {
                String roleName = Role.RoleType.getNameById(id.intValue()-1);
                String errText = String.format("Редактируемая роль '%s' является дефолтной", roleName);
                logger.error("400 " + errText);
                return ResponseEntity.badRequest().body(errText);
            } else {
                Optional<Role> currentRoleOpt = roleService.findRole(id);
                if (currentRoleOpt.isPresent()) {
                    Role roleWithSuchName = roleService.findRoleByName(role.getName());
                    if (roleWithSuchName != null) {
                        if (roleWithSuchName.getId() != id) {
                            String errText;
                            if(roleWithSuchName.getId()>= 1 && roleWithSuchName.getId() <= 8){
                                errText = String.format("Конфликт: роль с именем '%s' уже существует и является дефолтной, нельзя менять имя роли на дефолтное", roleWithSuchName.getName());
                            } else {
                                errText = String.format("Конфликт: роль с именем '%s' уже существует", roleWithSuchName.getName());
                            }
                            logger.error("409 " + errText);
                            return ResponseEntity.status(HttpStatus.CONFLICT).body(errText);
                        } else return ResponseEntity.ok(roleService.updateRole(id, role));
                    }
                    return ResponseEntity.ok(roleService.updateRole(id, role));
                } else {
                    String errText = String.format("404 Роль c id='%d' не найдена", id);
                    logger.error(errText);
                    return ResponseEntity.notFound().build();
                }
            }
        } else {
            String errText = "409 role.id не может быть null";
            logger.error(errText);
            return ResponseEntity.badRequest().body(errText);
        }
    }

    @GetMapping("/{id}")
    @ResponseBody
    @ApiOperation(value = "Получение роли", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Успешно"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 404, message = "Роль c таким id не найдена")
    })
    public ResponseEntity<Role> getRole(@RequestHeader("Authorization") String bearerToken,
                                        @PathVariable Long id) {
        Optional<Role> currentRoleOpt = roleService.findRole(id);
        if(currentRoleOpt.isPresent()) {
            return ResponseEntity.ok(currentRoleOpt.get());
        } else {
            String errText = String.format("404 Роль c id='%d' не найдена", id);
            logger.error(errText);
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    @ResponseBody
    @ApiOperation(value = "Удаление роли (статус меняется на DELETED)", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Успешно"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 404, message = "Роль c таким id не найдена")
    })
    public ResponseEntity deleteRole(@RequestHeader("Authorization") String bearerToken,
                                     @PathVariable Long id) {
        if (id >= 1 && id <= 8) {
            String roleName = Role.RoleType.getNameById(id.intValue()-1);
            String errText = String.format("Удаляемая роль '%s' является дефолтной", roleName);
            logger.error("400 " + errText);
            return ResponseEntity.badRequest().body(errText);
        }
        {
            Optional<Role> currentRoleOpt = roleService.findRole(id);
            if (currentRoleOpt.isPresent()) {
                Role currentRole = currentRoleOpt.get();
                if(currentRole.isDefault()) {
                    String errText = String.format("Удаляемая роль '%s' является дефолтной", currentRole.getName());
                    logger.error("400 " + errText);
                    return ResponseEntity.badRequest().body(errText);
                } else {
                    roleService.delete(currentRole);
                    return ResponseEntity.ok().build();
                }
            } else {
                String errText = String.format("404 Роль c id='%d' не найдена", id);
                logger.error(errText);
                return ResponseEntity.notFound().build();
            }
        }
    }


    @GetMapping("/{id}/permissions")
    @ResponseBody
    @ApiOperation(value = "Получение разрешений для роли", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Успешно"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 404, message = "Роль c таким id не найдена")
    })
    public ResponseEntity<List<PermissionDTO>> getRolePermissions(@RequestHeader("Authorization") String bearerToken,
                                                                 @PathVariable Long id) {
        Optional<Role> currentRoleOpt = roleService.findRole(id);
        if(currentRoleOpt.isPresent()) {
            return ResponseEntity.ok(roleService.getPermissionsWithStatus(id));
        } else {
            String errText = String.format("404 Роль c id='%d' не найдена", id);
            logger.error(errText);
            return ResponseEntity.notFound().build();
        }
    }


    @PutMapping("/{id}/permissions")
    @ResponseBody
    @ApiOperation(value = "Сохранение разрешений для роли", response = Role.class)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Успешно"),
            @ApiResponse(code = 400, message = "Недостаточно прав"),
            @ApiResponse(code = 403, message = "Недостаточно прав"),
            @ApiResponse(code = 404, message = "Роль c таким id не найдена")
    })
    public ResponseEntity saveRolePermissions(@RequestHeader("Authorization") String bearerToken,
                                              @PathVariable Long id,
                                              @RequestBody List<Permission> permissions) {
        if (id == 1 || id == 2) {
            String roleName = id == 1 ? "Сотрудник" : "Администратор";

            String errText = String.format("Роль '%s' является дефолтной, нельзя менять разрешения роли", roleName);
            logger.error("400 " + errText);
            return ResponseEntity.badRequest().body(errText);
        }

        Optional<Role> currentRoleOpt = roleService.findRole(id);
        if(currentRoleOpt.isPresent()) {
            Role role = currentRoleOpt.get();
            roleService.saveRolePermissions(role, permissions);
            return ResponseEntity.ok(roleService.getPermissions(role.getId()));
        } else {
            String errText = String.format("404 Роль c id='%d' не найдена", id);
            logger.error(errText);
            return ResponseEntity.notFound().build();
        }
    }

}
