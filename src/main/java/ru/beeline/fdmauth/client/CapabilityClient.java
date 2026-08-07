package ru.beeline.fdmauth.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import ru.beeline.fdmauth.dto.cx.HasAccessDTO;

@Component
@RequiredArgsConstructor
@Slf4j
public class CapabilityClient {

    private final RestTemplate restTemplate;

    @Value("${integration.capability-server-url}")
    private String baseUrl;

    public boolean checkBcOrderDraftOwner(Integer orderId, Integer userId) {
        try {
            String url = UriComponentsBuilder
                    .fromHttpUrl(baseUrl + "/api/v1/internal/check/bc-order-draft/{id}/owner")
                    .uriVariables(java.util.Map.of("id", orderId))
                    .queryParam("userId", userId)
                    .toUriString();
            HasAccessDTO result = restTemplate.getForObject(url, HasAccessDTO.class);
            return result != null && result.isHasAccess();
        } catch (Exception e) {
            log.warn("BC_ORDER_DRAFT_OWNER check failed for orderId={}: {}", orderId, e.getMessage());
            return false;
        }
    }
}
