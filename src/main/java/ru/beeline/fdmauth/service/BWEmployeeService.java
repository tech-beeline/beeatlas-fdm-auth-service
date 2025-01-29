package ru.beeline.fdmauth.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;
import ru.beeline.fdmauth.dto.bw.BWToken;
import ru.beeline.fdmauth.dto.bw.EmployeeProductsDTO;

import static ru.beeline.fdmauth.utils.RestHelper.getRestTemplate;

@Slf4j
@Service
public class BWEmployeeService {

    private static String accessToken = "";

    @Value("${gwurl}")
    private String gwUrl;

    @Value("${authbasic}")
    private String authBasic;

    @Value("${techuser}")
    private String techUser;

    @Value("${techpassword}")
    private String techPassword;

    private static int attemptCounter = 0;

    public EmployeeProductsDTO getEmployeeInfo(String employeeLogin){
        EmployeeProductsDTO employeeProductsDTO = new EmployeeProductsDTO();
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer "+ accessToken);

            HttpEntity<String> entity = new HttpEntity<>(headers);

            final RestTemplate restTemplate = getRestTemplate();

            employeeProductsDTO = restTemplate.exchange(
                    gwUrl + "/bw-roles/v0/v2/users/action/search/by-login/"
                            + employeeLogin,
                    HttpMethod.GET, entity, EmployeeProductsDTO.class).getBody();
        } catch (HttpClientErrorException.Unauthorized e) {
            log.error(e.getMessage());
            if(attemptCounter < 3) {
                attemptCounter++;
                log.info("The MAPIC token update attempt: " + attemptCounter);
                updateAccessToken();
                employeeProductsDTO = getEmployeeInfo(employeeLogin);
            } else {
                attemptCounter = 0;
                log.error(e.getMessage());
            }

        } catch (Exception e) {
            attemptCounter = 0;
            log.error(e.getMessage());
        }
        attemptCounter = 0;
        return employeeProductsDTO;
    }


    public void updateAccessToken() {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            headers.set("Authorization", "Basic "+ authBasic);

            MultiValueMap<String, String> bodyParamMap = new LinkedMultiValueMap<>();
            bodyParamMap.add("grant_type", "client_credentials");
            bodyParamMap.add("username", techUser);
            bodyParamMap.add("password", techPassword);

            HttpEntity<MultiValueMap<String, String>> entity = new HttpEntity<>(bodyParamMap, headers);
            final RestTemplate restTemplate = getRestTemplate();

            BWToken token = restTemplate.exchange(
                    gwUrl + "/gw-auth/1.0.0/token",
                    HttpMethod.POST, entity, BWToken.class).getBody();
            if (token != null) {
                log.info("The MAPIC token has been updated");
                accessToken = token.getAccessToken();
            }
        } catch (Exception e) {
            log.error(e.getMessage());
        }
    }

    public String getAccessToken(){
        return accessToken;
    }

}
