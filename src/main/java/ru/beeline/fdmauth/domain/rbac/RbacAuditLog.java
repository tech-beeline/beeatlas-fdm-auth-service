/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.domain.rbac;

import lombok.*;

import javax.persistence.*;
import java.time.LocalDateTime;

@Builder
@Data
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "rbac_audit_log", schema = "user_auth")
public class RbacAuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id")
    private Integer userId;

    @Column(name = "method", nullable = false)
    private String method;

    @Column(name = "path", nullable = false)
    private String path;

    @Column(name = "ts", nullable = false)
    private LocalDateTime ts;

    @Column(name = "effect", nullable = false)
    private String effect;

    @Column(name = "description")
    private String description;

    @Column(name = "params")
    private String params;
}
