/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.dto.product;

import lombok.*;

@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductPutDto {
    private String name;
    private String description;
    private String gitUrl;
    private String structurizrWorkspaceName;
    private String structurizrApiKey;
    private String structurizrApiSecret;
    private String structurizrApiUrl;
}
