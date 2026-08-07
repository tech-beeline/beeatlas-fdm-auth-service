package ru.beeline.fdmauth.dto;

import lombok.*;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateUserRequestDTO {
    private String login;
    private String fullName;
    private String idExt;
    private String email;
}

