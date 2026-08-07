/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.dto.rbac;

import lombok.*;

import java.util.List;

@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class PolicyFullDTO {

    private Long id;
    private String pathMask;
    private String httpMethod;
    private String roleAlias;
    private String permissionAlias;
    private String effect;
    private Integer priority;
    private List<String> checkTypeNames;
}
