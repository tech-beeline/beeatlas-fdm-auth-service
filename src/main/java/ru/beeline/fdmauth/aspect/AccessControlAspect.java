package ru.beeline.fdmauth.aspect;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import ru.beeline.fdmauth.exception.MethodUnauthorizedException;
import ru.beeline.fdmauth.exception.OnlyAdminAccessException;

import javax.servlet.http.HttpServletRequest;
import java.util.Arrays;
import java.util.List;

import static ru.beeline.fdmauth.utils.Constant.*;

@Aspect
@Component
public class AccessControlAspect {

    @Around("@annotation(AccessControl)")
    public Object checkAdminAccess(ProceedingJoinPoint joinPoint) throws Throwable {
        String userRoles = validateHeaders();

        boolean isAdmin = toList(userRoles).contains("ADMINISTRATOR");
        if (!isAdmin) throw new OnlyAdminAccessException("403 Permission denied");

        return joinPoint.proceed();
    }

    @Around("@annotation(HeaderControl)")
    public Object checkHeaders(ProceedingJoinPoint joinPoint) throws Throwable {
        validateHeaders();
        return joinPoint.proceed();
    }

    private String validateHeaders() {
        HttpServletRequest request = ((ServletRequestAttributes) RequestContextHolder.getRequestAttributes()).getRequest();

        String userId = request.getHeader(USER_ID_HEADER);
        String productsIds = request.getHeader(USER_PRODUCTS_IDS_HEADER);
        String userPermissions = request.getHeader(USER_PERMISSIONS_HEADER);
        String userRoles = request.getHeader(USER_ROLES_HEADER);

        if (userId == null || productsIds == null || userPermissions == null || userRoles == null) {
            throw new MethodUnauthorizedException("401 Unauthorized");
        }
        return userRoles;
    }

    private List<String> toList(String value) {
        return Arrays.asList(
                value.replaceAll("^\\[|\\]$|\"", "").split(",")
        );
    }
}
