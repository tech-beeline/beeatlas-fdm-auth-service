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
public class AuthorizeResponseDTO {

    private String decision;
    private Integer userId;
    private List<Long> productIds;
    private List<String> roles;
    private List<String> permissions;
    private String message;
}
