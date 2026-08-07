/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.client;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import ru.beeline.fdmauth.dto.myprofile.MyProfileEmployeesResponse;

import java.net.URI;

@Component
@RequiredArgsConstructor
public class MyProfileClient {

    private final RestTemplate restTemplate;

    @Value("${integration.myprofile-server-url}")
    private String baseUrl;

    @Value("${integration.myprofile.token}")
    private String token;

    public MyProfileEmployeesResponse searchEmployees(String search, Integer employeeNumber) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(baseUrl + "/myprofile/api/v1/")
                .pathSegment("employees")
                .queryParam("is_dismissed", "false");
        if (search != null && !search.isBlank()) {
            builder.queryParam("search", search);
        }
        if (employeeNumber != null) {
            builder.queryParam("employee_number", employeeNumber);
        }
        URI uri = builder.build().toUri();

        HttpHeaders headers = new HttpHeaders();
        if (token != null && !token.isBlank()) {
            headers.set(HttpHeaders.AUTHORIZATION, "Token " + token);
        }

        RequestEntity<Void> request = new RequestEntity<>(headers, HttpMethod.GET, uri);
        ResponseEntity<MyProfileEmployeesResponse> response = restTemplate.exchange(
                request,
                MyProfileEmployeesResponse.class
        );
        return response.getBody();
    }
}

