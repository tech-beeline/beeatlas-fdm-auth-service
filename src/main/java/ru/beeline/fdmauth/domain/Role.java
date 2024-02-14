package ru.beeline.fdmauth.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.swagger.annotations.ApiModelProperty;
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

    @Enumerated(value = EnumType.STRING)
    private RoleType alias;

    private boolean deleted;

    public boolean isDefault() {
        return alias.equals(RoleType.DEFAULT);
    }

    @ApiModelProperty(hidden = true)
    @OneToMany(mappedBy = "role", cascade = CascadeType.ALL)
    List<RolePermission> permissions;

    @JsonIgnore
    @ApiModelProperty(hidden = true)
    @OneToMany(mappedBy = "role")
    List<UserRoles> userRoles;

    @Getter
    public enum RoleType {
        DEFAULT("Сотрудник"),
        ADMINISTRATOR("Администратор");

        private final String roleName;

        private static final RoleType[] values = RoleType.values();

        RoleType(String roleName) {
            this.roleName = roleName;
        }

        public static String getNameById(int id){
            return values[id].getRoleName();
        }
    }

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
