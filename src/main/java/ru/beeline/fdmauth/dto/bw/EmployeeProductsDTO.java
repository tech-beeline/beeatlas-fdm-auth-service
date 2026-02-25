/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.dto.bw;

import lombok.Data;
import lombok.Getter;
import java.util.List;

@Data
@Getter
public class EmployeeProductsDTO {

    private String firstName;
    private String lastName;
    private List<BWRole> bwRoles;

}
