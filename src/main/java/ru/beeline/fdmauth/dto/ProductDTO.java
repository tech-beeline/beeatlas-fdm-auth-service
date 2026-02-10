package ru.beeline.fdmauth.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;


@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class ProductDTO {

    @JsonProperty("id")
    private Integer id;

    @JsonProperty("name")
    private String name;

    @JsonProperty("alias")
    private String alias;

    @JsonProperty("description")
    private String description;

    @JsonProperty("git_url")
    private String gitUrl;

    @JsonProperty("structurizr_workspace_name")
    private String structurizrWorkspaceName;

    @JsonProperty("structurizr_api_key")
    private String structurizrApiKey;

    @JsonProperty("structurizr_api_secret")
    private String structurizrApiSecret;

    @JsonProperty("structurizr_api_url")
    private String structurizrApiUrl;

}
