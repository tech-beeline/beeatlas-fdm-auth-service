/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class EmailResponseDTO {

    private String email;

    public EmailResponseDTO(String email) {
        this.email = email;
    }
    public EmailResponseDTO() {
    }
}
