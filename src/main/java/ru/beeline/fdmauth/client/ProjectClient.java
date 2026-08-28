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
public class ProjectClient {

    private final RestTemplate restTemplate;

    @Value("${integration.project-server-url}")
    private String baseUrl;

    public boolean checkProjectOwner(Integer projectId, Integer userId) {
        try {
            String url = UriComponentsBuilder
                    .fromHttpUrl(baseUrl + "/api/v1/internal/check/project/{id}/owner")
                    .uriVariables(java.util.Map.of("id", projectId))
                    .queryParam("userId", userId)
                    .toUriString();
            HasAccessDTO result = restTemplate.getForObject(url, HasAccessDTO.class);
            return result != null && result.isHasAccess();
        } catch (Exception e) {
            log.warn("PROJECT_OWNER check failed for projectId={}: {}", projectId, e.getMessage());
            return false;
        }
    }
}
