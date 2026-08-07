package ru.beeline.fdmauth.dto;

import lombok.*;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateUserResponseDTO {
    private String login;
    private String fullName;
    private String idExt;
    private String email;
    private Integer id;
}

