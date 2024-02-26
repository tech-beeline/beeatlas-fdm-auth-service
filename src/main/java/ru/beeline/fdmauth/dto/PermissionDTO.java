package ru.beeline.fdmauth.dto;

import lombok.*;
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
    private PermissionTypeDTO alias;

    private boolean active = false;

}
