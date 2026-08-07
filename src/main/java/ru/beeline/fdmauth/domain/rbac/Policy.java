/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.domain.rbac;

import lombok.*;

import javax.persistence.*;

@Builder
@Data
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "policy", schema = "user_auth")
public class Policy {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "policy_id_seq")
    @SequenceGenerator(name = "policy_id_seq", sequenceName = "policy_id_seq", allocationSize = 1)
    private Long id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "route_id")
    private Route route;

    @Column(name = "role_alias")
    private String roleAlias;

    @Column(name = "permission_alias")
    private String permissionAlias;

    @Column(name = "effect")
    private String effect;

    @Column(name = "priority")
    private Integer priority;

    // logical reference to check_group.group_id (not a FK to check_group.id)
    @Column(name = "check_group_id")
    private Integer checkGroupId;
}
