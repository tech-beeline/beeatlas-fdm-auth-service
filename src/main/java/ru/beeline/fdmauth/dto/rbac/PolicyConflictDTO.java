/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.dto.rbac;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PolicyConflictDTO {
    private PolicyFullDTO existing;
    private PolicyFullDTO incoming;
}
