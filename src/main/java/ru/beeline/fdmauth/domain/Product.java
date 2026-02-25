/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.domain;

import lombok.*;
import javax.persistence.*;

@Builder
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "product", schema = "user_auth")
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "product_id_rec_generator")
    @SequenceGenerator(name = "product_id_rec_generator", sequenceName = "product_id_rec_seq", allocationSize = 1)
    private Long id;

    private String name;

    private String alias;

}