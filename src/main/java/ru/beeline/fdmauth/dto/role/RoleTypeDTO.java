package ru.beeline.fdmauth.dto.role;

import lombok.Getter;

@Getter
public enum RoleTypeDTO {
    DEFAULT("Сотрудник"),
    ADMINISTRATOR("Администратор");

    private final String roleName;

    private static final RoleTypeDTO[] values = RoleTypeDTO.values();

    RoleTypeDTO(String roleName) {
        this.roleName = roleName;
    }

    public static String getNameById(int id){
        return values[id].getRoleName();
    }
}