package ru.beeline.fdmauth.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import ru.beeline.fdmauth.dto.cx.CxOwnerReassignRequestDTO;
import ru.beeline.fdmauth.dto.cx.HasAccessDTO;

import java.net.URI;
import java.util.List;

import static ru.beeline.fdmauth.utils.Constant.*;

@Component
@RequiredArgsConstructor
@Slf4j
public class CxClient {

    private final RestTemplate restTemplate;

    @Value("${integration.cx-server-url}")
    private String baseUrl;

    public void reassignOwner(Integer currentUserId, Integer newUserId) {
        URI uri = URI.create(baseUrl + "/api/cx/v1/cj/owners/reassign");

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.add(USER_ID_HEADER, newUserId.toString());

        CxOwnerReassignRequestDTO body = new CxOwnerReassignRequestDTO(currentUserId, newUserId);
        RequestEntity<CxOwnerReassignRequestDTO> request = new RequestEntity<>(body, headers, HttpMethod.PATCH, uri);

        ResponseEntity<Void> response = restTemplate.exchange(request, Void.class);
        if (!response.getStatusCode().is2xxSuccessful()) {
            throw new IllegalStateException("CX reassign failed: " + response.getStatusCode());
        }
    }

    public boolean checkBiProductMember(Long biId, List<Long> productIds) {
        try {
            UriComponentsBuilder builder = UriComponentsBuilder
                    .fromHttpUrl(baseUrl + "/api/cx/v1/internal/check/bi/{id}/product-member")
                    .uriVariables(java.util.Map.of("id", biId));
            for (Long pid : productIds) {
                builder.queryParam("productIds", pid);
            }
            HasAccessDTO result = restTemplate.getForObject(builder.toUriString(), HasAccessDTO.class);
            return result != null && result.isHasAccess();
        } catch (Exception e) {
            log.warn("BI_PRODUCT_MEMBER check failed for bi={}: {}", biId, e.getMessage());
            return false;
        }
    }

    public boolean checkCjProductMember(Long cjId, List<Long> productIds) {
        try {
            UriComponentsBuilder builder = UriComponentsBuilder
                    .fromHttpUrl(baseUrl + "/api/cx/v1/internal/check/cj/{id}/product-member")
                    .uriVariables(java.util.Map.of("id", cjId));
            for (Long pid : productIds) {
                builder.queryParam("productIds", pid);
            }
            HasAccessDTO result = restTemplate.getForObject(builder.toUriString(), HasAccessDTO.class);
            return result != null && result.isHasAccess();
        } catch (Exception e) {
            log.warn("CJ_PRODUCT_MEMBER check failed for cj={}: {}", cjId, e.getMessage());
            return false;
        }
    }

    public boolean checkBiEditAccess(Long biId, List<Long> productIds) {
        try {
            UriComponentsBuilder builder = UriComponentsBuilder
                    .fromHttpUrl(baseUrl + "/api/cx/v1/internal/check/bi/{id}/edit-access")
                    .uriVariables(java.util.Map.of("id", biId));
            for (Long pid : productIds) {
                builder.queryParam("productIds", pid);
            }
            HasAccessDTO result = restTemplate.getForObject(builder.toUriString(), HasAccessDTO.class);
            return result != null && result.isHasAccess();
        } catch (Exception e) {
            log.warn("BI_EDIT_PRODUCT_MEMBER check failed for bi={}: {}", biId, e.getMessage());
            return false;
        }
    }

    public boolean checkCjEditAccess(Long cjId, List<Long> productIds) {
        try {
            UriComponentsBuilder builder = UriComponentsBuilder
                    .fromHttpUrl(baseUrl + "/api/cx/v1/internal/check/cj/{id}/edit-access")
                    .uriVariables(java.util.Map.of("id", cjId));
            for (Long pid : productIds) {
                builder.queryParam("productIds", pid);
            }
            HasAccessDTO result = restTemplate.getForObject(builder.toUriString(), HasAccessDTO.class);
            return result != null && result.isHasAccess();
        } catch (Exception e) {
            log.warn("CJ_EDIT_PRODUCT_MEMBER check failed for cj={}: {}", cjId, e.getMessage());
            return false;
        }
    }

    public boolean checkCjStepProductMember(Long stepId, List<Long> productIds) {
        try {
            UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(baseUrl + "/api/cx/v1/internal/check/cj-step/{id}/product-member")
                    .uriVariables(java.util.Map.of("id", stepId));
            for (Long pid : productIds) {
                builder.queryParam("productIds", pid);
            }
            HasAccessDTO result = restTemplate.getForObject(builder.toUriString(), HasAccessDTO.class);
            return result != null && result.isHasAccess();
        } catch (Exception e) {
            log.warn("CJ_STEP_PRODUCT_MEMBER check failed for step={}: {}", stepId, e.getMessage());
            return false;
        }
    }
}

