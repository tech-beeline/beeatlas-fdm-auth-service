package ru.beeline.fdmauth.dto;

import lombok.*;
import ru.beeline.fdmauth.domain.Permission;
import ru.beeline.fdmauth.domain.Role;
import java.util.List;

@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class UserInfoDTO {

    private Long id;
    private List<Long> productsIds;

    private List<Role.RoleType> roles;

    private List<Permission.PermissionType> permissions;

}
