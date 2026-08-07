package ru.beeline.fdmauth.dto.myprofile;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;

@Data
public class MyProfileEmployee {
    private Long id;
    @JsonProperty("user_name")
    private String userName;
    @JsonProperty("first_name")
    private String firstName;
    @JsonProperty("last_name")
    private String lastName;
    @JsonProperty("middle_name")
    private String middleName;
    @JsonProperty("employee_number")
    private String employeeNumber;
    private String email;

    @JsonProperty("employee_position_set")
    private List<MyProfileEmployeePosition> employeePositionSet;
}

