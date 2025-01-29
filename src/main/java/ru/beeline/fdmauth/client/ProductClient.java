package ru.beeline.fdmauth.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import ru.beeline.fdmauth.dto.ProductDTO;
import ru.beeline.fdmlib.dto.product.ProductPutDto;

import java.util.List;

import static ru.beeline.fdmauth.utils.Constant.USER_ID_HEADER;

@Slf4j
@Service
public class ProductClient {

    RestTemplate restTemplate;
    private final String productServerUrl;

    public ProductClient(@Value("${integration.products-server-url}") String productServerUrl, RestTemplate restTemplate) {
        this.productServerUrl = productServerUrl;
        this.restTemplate = restTemplate;
    }

    public List<ProductDTO> getProductByUserID(Long userId) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.add("SOURCE", "Sparx");
            headers.add(USER_ID_HEADER, userId.toString());

            return restTemplate.exchange(productServerUrl + "/api/v1/user/product",
                    HttpMethod.GET, new HttpEntity(headers), new ParameterizedTypeReference<List<ProductDTO>>() {
                    }).getBody();

        } catch (Exception e) {
            log.error(e.getMessage());
        }
        return null;
    }

    public HttpStatus postProduct(List<String> productCodes, String userId) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.add("SOURCE", "Sparx");

            HttpEntity<ProductPutDto> entity = new HttpEntity(productCodes, headers);
            return restTemplate.exchange(productServerUrl + "/api/v1/user/" + userId + "/products",
                    HttpMethod.POST, entity, Object.class).getStatusCode();
        } catch (Exception e) {
            log.error(e.getMessage());
        }
        return null;
    }
}
