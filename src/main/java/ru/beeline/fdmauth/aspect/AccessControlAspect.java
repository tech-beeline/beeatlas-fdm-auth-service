package ru.beeline.fdmauth.aspect;

import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import ru.beeline.fdmauth.domain.Role;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.exception.MethodUnauthorizedException;
import ru.beeline.fdmauth.exception.OnlyAdminAccessException;
import ru.beeline.fdmauth.service.*;
import ru.beeline.fdmauth.utils.jwt.JwtUserData;
import ru.beeline.fdmauth.utils.jwt.JwtUtils;
import java.util.Arrays;

@Aspect
@Component
@Slf4j
public class AccessControlAspect {

    @Autowired
    private UserService userService;

    @Autowired
    private RoleService roleService;

    @Autowired
    private ProductService productService;

    @Around(value = "@annotation(AdminAccessControl)")
    public Object checkAccess(ProceedingJoinPoint joinPoint) throws Throwable {
        Object[] args = joinPoint.getArgs();
        Long userId = (Long) args[0];
        long[] userProductIds = (long[]) args[1];
        String[] userRoles = (String[]) args[2];
        String[] userPermissions = (String[]) args[3];

        if (userId == null ||
                userProductIds == null || userProductIds.length == 0 ||
                userRoles == null || userRoles.length == 0 ||
                userPermissions == null || userPermissions.length == 0) {
            throw new MethodUnauthorizedException("Обязательные Headers отсутствуют");
        }

        boolean isAdmin = Arrays.asList(userRoles).contains(Role.RoleType.ADMINISTRATOR.name());
        if (!isAdmin) {
            throw new OnlyAdminAccessException("Доступ запрещен. Недостаточно прав у пользователя.");
        }
        log.info("Method access was successful");


        return joinPoint.proceed();
    }


    @Transactional(transactionManager = "transactionManager")
    public void validateAccess(String bearerToken) {
        UserProfile user;
        validate(bearerToken);

        JwtUserData userData = JwtUtils.getUserData(bearerToken);

    }

    private void validate(String bearerToken) {
        log.error("");
    }
}
