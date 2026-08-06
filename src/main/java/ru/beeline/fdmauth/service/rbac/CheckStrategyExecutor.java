/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.service.rbac;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import ru.beeline.fdmauth.client.CapabilityClient;
import ru.beeline.fdmauth.client.CxClient;
import ru.beeline.fdmauth.client.FdmBpmClient;
import ru.beeline.fdmauth.domain.rbac.CheckGroup;
import ru.beeline.fdmauth.dto.UserInfoDTO;

import java.util.Collections;
import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class CheckStrategyExecutor {

    private final CxClient cxClient;
    private final CapabilityClient capabilityClient;
    private final FdmBpmClient fdmBpmClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public boolean execute(CheckGroup check, UserInfoDTO userInfo,
                           Map<String, String> pathVars, Map<String, String> queryParams,
                           String bodyJson) {
        boolean result;
        switch (check.getCheckType().getName()) {
            case "PRODUCT_MEMBER":              result = checkProductMember(userInfo); break;
            case "INDIRECT_PRODUCT_MEMBER":     result = checkIndirectProductMember(userInfo, pathVars, queryParams); break;
            case "AUTHOR":                      result = checkAuthor(userInfo, pathVars, queryParams); break;
            case "OWNER":                       result = checkOwner(userInfo, pathVars, queryParams); break;
            case "BI_PRODUCT_MEMBER":           result = checkBiProductMember(userInfo, pathVars); break;
            case "BI_EDIT_PRODUCT_MEMBER":      result = checkBiEditAccess(userInfo, pathVars); break;
            case "PRODUCT_MEMBER_FROM_BODY":    result = checkProductMemberFromBody(check, userInfo, bodyJson); break;
            case "BC_ORDER_DRAFT_OWNER":        result = checkBcOrderDraftOwner(userInfo, pathVars); break;
            case "APPLICATION_AUTHOR_OR_EXECUTOR": result = checkApplicationAuthorOrExecutor(userInfo, pathVars); break;
            case "APPLICATION_CURRENT_EXECUTOR":   result = checkApplicationCurrentExecutor(userInfo, pathVars); break;
            default:
                log.warn("Unknown check type: {}, returning false", check.getCheckType().getName());
                result = false;
        }
        log.info("RBAC check[type={} group={}] pathVars={} -> {}", check.getCheckType().getName(), check.getGroupId(), pathVars, result ? "ALLOW" : "DENY");
        return result;
    }

    private boolean checkProductMember(UserInfoDTO userInfo) {
        log.warn("PRODUCT_MEMBER not yet implemented");
        return false;
    }

    private boolean checkIndirectProductMember(UserInfoDTO userInfo, Map<String, String> pathVars, Map<String, String> queryParams) {
        log.warn("INDIRECT_PRODUCT_MEMBER not yet implemented");
        return false;
    }

    private boolean checkAuthor(UserInfoDTO userInfo, Map<String, String> pathVars, Map<String, String> queryParams) {
        log.warn("AUTHOR not yet implemented");
        return false;
    }

    private boolean checkOwner(UserInfoDTO userInfo, Map<String, String> pathVars, Map<String, String> queryParams) {
        log.warn("OWNER not yet implemented");
        return false;
    }

    private boolean checkBiProductMember(UserInfoDTO userInfo, Map<String, String> pathVars) {
        String idStr = pathVars.get("id");
        if (idStr == null) {
            log.warn("BI_PRODUCT_MEMBER: path var 'id' missing");
            return false;
        }
        return cxClient.checkBiProductMember(
                Long.parseLong(idStr),
                userInfo.getProductsIds() != null ? userInfo.getProductsIds() : Collections.emptyList()
        );
    }

    private boolean checkBiEditAccess(UserInfoDTO userInfo, Map<String, String> pathVars) {
        String idStr = pathVars.get("id");
        if (idStr == null) {
            log.warn("BI_EDIT_PRODUCT_MEMBER: path var 'id' missing");
            return false;
        }
        return cxClient.checkBiEditAccess(
                Long.parseLong(idStr),
                userInfo.getProductsIds() != null ? userInfo.getProductsIds() : Collections.emptyList()
        );
    }

    private boolean checkBcOrderDraftOwner(UserInfoDTO userInfo, Map<String, String> pathVars) {
        String idStr = pathVars.get("id");
        if (idStr == null) {
            log.warn("BC_ORDER_DRAFT_OWNER: path var 'id' missing");
            return false;
        }
        if (userInfo.getId() == null) {
            log.warn("BC_ORDER_DRAFT_OWNER: userId is null");
            return false;
        }
        return capabilityClient.checkBcOrderDraftOwner(Integer.parseInt(idStr), userInfo.getId());
    }

    private boolean checkApplicationAuthorOrExecutor(UserInfoDTO userInfo, Map<String, String> pathVars) {
        String businessKey = pathVars.get("business_key");
        if (businessKey == null) {
            log.warn("APPLICATION_AUTHOR_OR_EXECUTOR: path var 'business_key' missing");
            return false;
        }
        if (userInfo.getId() == null) {
            log.warn("APPLICATION_AUTHOR_OR_EXECUTOR: userId is null");
            return false;
        }
        return fdmBpmClient.checkApplicationAuthorOrExecutor(businessKey, userInfo.getId());
    }

    private boolean checkApplicationCurrentExecutor(UserInfoDTO userInfo, Map<String, String> pathVars) {
        String businessKey = pathVars.get("business_key");
        if (businessKey == null) {
            log.warn("APPLICATION_CURRENT_EXECUTOR: path var 'business_key' missing");
            return false;
        }
        if (userInfo.getId() == null) {
            log.warn("APPLICATION_CURRENT_EXECUTOR: userId is null");
            return false;
        }
        return fdmBpmClient.checkApplicationCurrentExecutor(businessKey, userInfo.getId());
    }

    private boolean checkProductMemberFromBody(CheckGroup check, UserInfoDTO userInfo, String bodyJson) {
        if (bodyJson == null || check.getParamKey() == null) {
            log.warn("PRODUCT_MEMBER_FROM_BODY: bodyJson or paramKey is null, paramKey={}, bodyJson={}",
                    check.getParamKey(), bodyJson);
            return false;
        }
        try {
            JsonNode val = objectMapper.readTree(bodyJson).findValue(check.getParamKey());
            Long extractedId = (val == null || val.isNull()) ? null : val.asLong();
            // productId в теле отсутствует — сущность создаётся/редактируется без продукта,
            // членство в продукте в этом случае проверять не по чему, пропускаем (ALLOW).
            boolean result = extractedId == null
                    || (userInfo.getProductsIds() != null && userInfo.getProductsIds().contains(extractedId));
            log.info("PRODUCT_MEMBER_FROM_BODY: paramKey={} extractedId={} userProductIds={} -> {}",
                    check.getParamKey(), extractedId, userInfo.getProductsIds(), result ? "ALLOW" : "DENY");
            return result;
        } catch (Exception e) {
            log.warn("PRODUCT_MEMBER_FROM_BODY: failed to parse body for key='{}': {}", check.getParamKey(), e.getMessage());
            return false;
        }
    }
}
