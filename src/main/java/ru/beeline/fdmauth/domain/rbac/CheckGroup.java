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
@Table(name = "check_group", schema = "user_auth")
public class CheckGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "check_group_id_seq")
    @SequenceGenerator(name = "check_group_id_seq", sequenceName = "check_group_id_seq", allocationSize = 1)
    private Long id;

    // logical group identifier — multiple rows with same groupId = AND checks
    @Column(name = "group_id")
    private Integer groupId;

    @Column(name = "name")
    private String name;

    @Column(name = "param_key")
    private String paramKey;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "check_type_id")
    private CheckType checkType;
}
