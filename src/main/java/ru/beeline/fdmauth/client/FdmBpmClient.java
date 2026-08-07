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
public class FdmBpmClient {

    private final RestTemplate restTemplate;

    @Value("${integration.camunda-server-url}")
    private String baseUrl;

    public boolean checkApplicationAuthorOrExecutor(String businessKey, Integer userId) {
        try {
            String url = UriComponentsBuilder
                    .fromHttpUrl(baseUrl + "/api/v1/internal/check/application/{businessKey}/author-or-executor")
                    .uriVariables(java.util.Map.of("businessKey", businessKey))
                    .queryParam("userId", userId)
                    .toUriString();
            HasAccessDTO result = restTemplate.getForObject(url, HasAccessDTO.class);
            return result != null && result.isHasAccess();
        } catch (Exception e) {
            log.warn("APPLICATION_AUTHOR_OR_EXECUTOR check failed for businessKey={}: {}", businessKey, e.getMessage());
            return false;
        }
    }

    public boolean checkApplicationCurrentExecutor(String businessKey, Integer userId) {
        try {
            String url = UriComponentsBuilder
                    .fromHttpUrl(baseUrl + "/api/v1/internal/check/application/{businessKey}/current-executor")
                    .uriVariables(java.util.Map.of("businessKey", businessKey))
                    .queryParam("userId", userId)
                    .toUriString();
            HasAccessDTO result = restTemplate.getForObject(url, HasAccessDTO.class);
            return result != null && result.isHasAccess();
        } catch (Exception e) {
            log.warn("APPLICATION_CURRENT_EXECUTOR check failed for businessKey={}: {}", businessKey, e.getMessage());
            return false;
        }
    }
}
