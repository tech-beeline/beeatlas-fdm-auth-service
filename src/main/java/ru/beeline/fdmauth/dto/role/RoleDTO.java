package ru.beeline.fdmauth.dto.role;

import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@EqualsAndHashCode(callSuper = true)
@Data
@NoArgsConstructor
public class RoleDTO extends RoleCreateDTO {
    private Long id;

    public RoleDTO(Long id, String name){
        super(name);
        this.id = id;
    }
}
