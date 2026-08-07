package ru.beeline.fdmauth.dto.myprofile;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class MyProfileEmployeePosition {
    @JsonProperty("func_manager_employee_number")
    private String funcManagerEmployeeNumber;
}

