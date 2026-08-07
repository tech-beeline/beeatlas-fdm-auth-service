package ru.beeline.fdmauth.dto.myprofile;

import lombok.*;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MyProfileUserSearchResultDTO {
    private String userName;
    private String fullName;
    private String employeeNumber;
    private String func_manager_employee_number;
    private String email;
    private Boolean beeAtlas;
    private Integer id;
}

