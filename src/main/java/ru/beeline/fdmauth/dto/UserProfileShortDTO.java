package ru.beeline.fdmauth.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import ru.beeline.fdmauth.dto.role.RoleInfoDTO;

import java.util.List;

@Getter
@Setter
@AllArgsConstructor
public class UserProfileShortDTO {

    private Long id;

    private String fullName;

    private String email;
}
