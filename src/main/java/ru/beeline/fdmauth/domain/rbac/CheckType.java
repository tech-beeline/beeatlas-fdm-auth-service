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
@Table(name = "check_type", schema = "user_auth")
public class CheckType {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "check_type_id_seq")
    @SequenceGenerator(name = "check_type_id_seq", sequenceName = "check_type_id_seq", allocationSize = 1)
    private Long id;

    @Column(name = "name", unique = true)
    private String name;

    @Column(name = "description")
    private String description;
}
