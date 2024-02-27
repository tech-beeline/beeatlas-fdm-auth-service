package ru.beeline.fdmauth.dto;

import lombok.*;
import ru.beeline.fdmauth.dto.role.RoleTypeDTO;

import java.util.List;

@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class UserInfoDTO {

    private Long id;
    private List<Long> productsIds;

    private List<RoleTypeDTO> roles;

    private List<PermissionTypeDTO> permissions;

}
