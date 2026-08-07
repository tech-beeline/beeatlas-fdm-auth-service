package ru.beeline.fdmauth.config;

import io.confluent.kafka.schemaregistry.client.security.bearerauth.BearerAuthCredentialProvider;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.net.URL;
import java.util.Map;
import java.util.concurrent.locks.ReentrantLock;

@Slf4j
public class OAuthSchemaRegistryCredentialProvider implements BearerAuthCredentialProvider {

    private static final int REFRESH_BEFORE_EXPIRY_SEC = 60;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ReentrantLock lock = new ReentrantLock();

    private String tokenEndpointUrl;
    private String clientId;
    private String username;
    private String password;

    private volatile String cachedToken;
    private volatile long expiryMs = 0;

    @Override
    public String alias() {
        return "CUSTOM";
    }

    @Override
    public void configure(Map<String, ?> configs) {
        this.tokenEndpointUrl = (String) configs.get("bearer.auth.issuer.endpoint.url");
        this.clientId         = (String) configs.get("bearer.auth.client.id");
        this.username         = (String) configs.get("bearer.auth.username");
        this.password         = (String) configs.get("bearer.auth.password");
    }

    @Override
    public String getBearerToken(URL url) {
        if (cachedToken == null || System.currentTimeMillis() >= expiryMs) {
            refreshToken();
        }
        return cachedToken;
    }

    private void refreshToken() {
        lock.lock();
        try {
            if (cachedToken != null && System.currentTimeMillis() < expiryMs) {
                return;
            }
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

            MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
            body.add("grant_type", "password");
            body.add("client_id", clientId);
            body.add("username", username);
            body.add("password", password);

            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(
                    tokenEndpointUrl, new HttpEntity<>(body, headers), Map.class);

            cachedToken = (String) response.get("access_token");
            int expiresIn = ((Number) response.get("expires_in")).intValue();
            expiryMs = System.currentTimeMillis() + (long) (expiresIn - REFRESH_BEFORE_EXPIRY_SEC) * 1000;

            log.info("Schema Registry OAuth token refreshed, valid for {} sec", expiresIn);
        } catch (Exception e) {
            log.error("Failed to obtain Schema Registry OAuth token", e);
            throw new RuntimeException("Cannot obtain Schema Registry bearer token", e);
        } finally {
            lock.unlock();
        }
    }
}
