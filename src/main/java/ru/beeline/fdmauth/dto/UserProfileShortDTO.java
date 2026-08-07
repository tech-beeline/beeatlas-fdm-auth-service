/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class UserProfileShortDTO {

    private Integer id;
    @JsonProperty("id_ext")
    private String idExt;
    private String fullName;
    private String email;
    private String login;
}
