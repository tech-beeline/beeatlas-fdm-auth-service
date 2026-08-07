/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.*;

import javax.persistence.*;
import java.util.List;

@Builder
@Data
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "role", schema = "user_auth")
public class Role {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator="role_id_seq")
    @SequenceGenerator(name="role_id_seq", sequenceName="role_id_seq", allocationSize=1)
    private Long id;

    private String name;

    private String descr;

    private String alias;

    private boolean deleted;

    public boolean isDefault() {
        return alias.equals("DEFAULT") || alias.equals("ADMINISTRATOR");
    }

    @Schema(hidden = true)
    @OneToMany(mappedBy = "role", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    List<RolePermission> permissions;

    @JsonIgnore
    @Schema(hidden = true)
    @OneToMany(mappedBy = "role")
    List<UserRoles> userRoles;

    @Override
    public String toString() {
        return "Role{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", descr='" + descr + '\'' +
                ", alias=" + alias +
                ", deleted=" + deleted +
                ", permissions=" + permissions +
                '}';
    }
}
