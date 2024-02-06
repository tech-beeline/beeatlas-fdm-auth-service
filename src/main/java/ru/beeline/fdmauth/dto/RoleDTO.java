package ru.beeline.fdmauth.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import ru.beeline.fdmauth.domain.Role;
import ru.beeline.fdmauth.domain.UserRoles;

import javax.persistence.EnumType;
import javax.persistence.Enumerated;
import java.util.List;
import java.util.stream.Collectors;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RoleDTO {

    private Long id;

    private String name;

    private String descr;

    @Enumerated(value = EnumType.STRING)
    private Role.RoleType alias;

    private boolean deleted;

    public RoleDTO(Role role) {
        this.id = role.getId();
        this.name = role.getName();
        this.descr = role.getDescr();
        this.alias = role.getAlias();
        this.deleted = role.isDeleted();
    }

    public static List<RoleDTO> convert(List<UserRoles> userRoles) {
        return userRoles.stream()
                .map(userRole -> new RoleDTO(userRole.getRole()))
                .collect(Collectors.toList());
    }
}
