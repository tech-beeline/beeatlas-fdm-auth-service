ALTER TABLE user_auth.user_product
    ADD CONSTRAINT unique_user_product_profile_product UNIQUE (id_profile, id_product);