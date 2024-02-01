package ru.beeline.fdmauth.domain;

import lombok.*;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

@Builder
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "product", schema = "user_auth")
public class Product {

    @Id
    @Column(name = "id_product_ext")
    private String id;

    private String name;

    private String alias;

}
