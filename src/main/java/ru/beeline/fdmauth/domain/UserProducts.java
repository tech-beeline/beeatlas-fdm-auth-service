package ru.beeline.fdmauth.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.SequenceGenerator;
import javax.persistence.Table;
import javax.persistence.UniqueConstraint;

@Builder
@Data
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "user_product", schema = "user_auth",
        uniqueConstraints = @UniqueConstraint(columnNames = {"id_profile", "id_product"}))
public class UserProducts {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "user_product_id_rec_generator")
    @SequenceGenerator(name = "user_product_id_rec_generator", sequenceName = "user_product_id_rec_seq", allocationSize = 1)
    @Column(name = "id_rec")
    private Long id;

    @ManyToOne
    @JoinColumn(name = "id_profile")
    private UserProfile userProfile;

    @ManyToOne
    @JoinColumn(name = "id_product")
    private Product product;
}
