package ru.beeline.fdmauth.dto.cx;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CxOwnerReassignRequestDTO {
    private Integer currentUserId;
    private Integer newUserId;
}

