package ru.beeline.fdmauth.dto;

import lombok.*;
import ru.beeline.fdmauth.domain.Permission;
import javax.persistence.EnumType;
import javax.persistence.Enumerated;

@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class PermissionDTO {

    private Long id;

    private String name;

    private String descr;

    @Enumerated(value = EnumType.STRING)
    private Permission.PermissionType alias;

    private boolean active = false;

}
