package ru.beeline.fdmauth.dto.role;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import ru.beeline.fdmauth.domain.Role;
import ru.beeline.fdmauth.domain.UserRoles;

import java.util.List;
import java.util.stream.Collectors;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RoleInfoDTO extends RoleDTO {

    private String descr;

    private String alias;

    private boolean deleted;

    public RoleInfoDTO(Role role) {
        super(role.getId(), role.getName());
        this.descr = role.getDescr();
        this.alias = role.getAlias();
        this.deleted = role.isDeleted();
    }

    public static List<RoleInfoDTO> convert(List<UserRoles> userRoles) {
        return userRoles.stream()
                .map(userRole -> new RoleInfoDTO(userRole.getRole()))
                .collect(Collectors.toList());
    }
}
