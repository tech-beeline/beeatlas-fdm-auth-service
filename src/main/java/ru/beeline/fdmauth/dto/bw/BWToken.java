/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.dto.bw;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.Getter;

import java.io.Serializable;

@Data
@Getter
public class BWToken implements Serializable {

    @JsonProperty("access_token")
    private String accessToken;

}
