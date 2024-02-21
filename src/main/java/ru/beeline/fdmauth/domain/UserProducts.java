package ru.beeline.fdmauth.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import javax.persistence.*;

@Builder
@Data
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "user_product", schema = "user_auth")
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
