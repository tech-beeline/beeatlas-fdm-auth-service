/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.*;

import javax.persistence.*;

@Builder
@Data
@AllArgsConstructor
@NoArgsConstructor
@Entity
@ToString(exclude = "role")
@Table(name = "role_permissions", schema = "user_auth")
public class RolePermission {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "role_permissions_id_rec_generator")
    @SequenceGenerator(name = "role_permissions_id_rec_generator", sequenceName = "role_permissions_id_rec_seq", allocationSize = 1)
    @Column(name = "id_rec")
    private Long id;

    @ManyToOne
    @JoinColumn(name = "id_permission")
    private Permission permission;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_role")
    private Role role;

    @Column(name = "b_set")
    private boolean bSet;

}
