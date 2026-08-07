/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.utils.jwt;

import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import net.minidev.json.JSONObject;
import java.util.Base64;
import java.util.Date;
import java.util.Map;

@Slf4j
public class JwtUtils {
    public static Map<String, String> encodeJWT(String token) {
        try {
            String[] parts = token.split("\\.");
            Base64.Decoder decoder = Base64.getUrlDecoder();

            String payload = new String(decoder.decode(parts[1]));
            String jsonObject = JSONObject.escape(payload).replace("\\", "");

            ObjectMapper mapper = new ObjectMapper();

            // convert JSON string to Map
            Map<String, String> map = mapper.readValue(jsonObject, Map.class);

            return map;

        } catch (Exception e) {
            log.error(e.getMessage());
        }

        return null;
    }

    public static String getEmail(String token) {
        Map<String, String> data = JwtUtils.encodeJWT(token.substring(token.indexOf(" ")));
        return data != null ? data.getOrDefault("email", null) : null;
    }

    public static JwtUserData getUserData(String token) {
        Map<String, String> data = JwtUtils.encodeJWT(token.substring(token.indexOf(" ")));
        return data != null ? new JwtUserData(data) : null;
    }

    public static boolean isExpired(String token) {
        DecodedJWT decodedJWT = JWT.decode(token.substring(token.indexOf(" ") + 1));
        Date expiresAt = decodedJWT.getExpiresAt();
        boolean isExpired = expiresAt.before(new Date());
        if (isExpired) {
            log.error("Token is expired, expired date: " + expiresAt);
        }
        return isExpired;
    }
}