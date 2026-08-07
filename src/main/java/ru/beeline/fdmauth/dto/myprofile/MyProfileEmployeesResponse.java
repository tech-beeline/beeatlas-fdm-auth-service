package ru.beeline.fdmauth.dto.myprofile;

import lombok.Data;

import java.util.List;

@Data
public class MyProfileEmployeesResponse {
    private Integer count;
    private String next;
    private String previous;
    private List<MyProfileEmployee> results;
}

