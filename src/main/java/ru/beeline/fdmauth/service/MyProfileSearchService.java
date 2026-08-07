/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import ru.beeline.fdmauth.client.MyProfileClient;
import ru.beeline.fdmauth.dto.UserProfileShortDTO;
import ru.beeline.fdmauth.dto.myprofile.MyProfileEmployee;
import ru.beeline.fdmauth.dto.myprofile.MyProfileEmployeesResponse;
import ru.beeline.fdmauth.dto.myprofile.MyProfileUserSearchResultDTO;

import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MyProfileSearchService {

    private final MyProfileClient myProfileClient;
    private final UserProfileService userProfileService;

    public List<MyProfileUserSearchResultDTO> search(String search, Integer employeeNumber) {
        MyProfileEmployeesResponse response = myProfileClient.searchEmployees(search, employeeNumber);
        List<MyProfileEmployee> employees = response != null && response.getResults() != null
                ? response.getResults()
                : Collections.emptyList();

        Map<String, UserProfileShortDTO> beeAtlasByIdExt = userProfileService.getAllUserProfileFdm().stream()
                .filter(u -> u.getIdExt() != null && !u.getIdExt().isBlank())
                .collect(Collectors.toMap(
                        UserProfileShortDTO::getIdExt,
                        Function.identity(),
                        (a, b) -> a
                ));

        return employees.stream()
                .map(emp -> {
                    UserProfileShortDTO atlasUser = emp.getEmployeeNumber() != null
                            ? beeAtlasByIdExt.get(emp.getEmployeeNumber())
                            : null;

                    return MyProfileUserSearchResultDTO.builder()
                            .userName(emp.getUserName())
                            .fullName(joinFullName(emp.getLastName(), emp.getFirstName(), emp.getMiddleName()))
                            .employeeNumber(emp.getEmployeeNumber())
                            .func_manager_employee_number(extractFuncManagerEmployeeNumber(emp))
                            .email(emp.getEmail())
                            .beeAtlas(atlasUser != null)
                            .id(atlasUser != null ? atlasUser.getId() : null)
                            .build();
                })
                .collect(Collectors.toList());
    }

    private String joinFullName(String lastName, String firstName, String middleName) {
        List<String> parts = new ArrayList<>();
        if (lastName != null && !lastName.isBlank()) parts.add(lastName);
        if (firstName != null && !firstName.isBlank()) parts.add(firstName);
        if (middleName != null && !middleName.isBlank()) parts.add(middleName);
        return String.join(" ", parts);
    }

    private String extractFuncManagerEmployeeNumber(MyProfileEmployee employee) {
        if (employee.getEmployeePositionSet() == null || employee.getEmployeePositionSet().isEmpty()) {
            return null;
        }
        return employee.getEmployeePositionSet().get(0).getFuncManagerEmployeeNumber();
    }
}

