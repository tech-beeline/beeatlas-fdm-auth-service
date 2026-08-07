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
@Table(name = "route", schema = "user_auth")
public class Route {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "route_id_seq")
    @SequenceGenerator(name = "route_id_seq", sequenceName = "route_id_seq", allocationSize = 1)
    private Long id;

    @Column(name = "path_mask")
    private String pathMask;

    @Column(name = "http_method")
    private String httpMethod;
}
