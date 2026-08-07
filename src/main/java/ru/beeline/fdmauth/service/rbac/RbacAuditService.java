/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.service.rbac;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import ru.beeline.fdmauth.domain.rbac.RbacAuditLog;
import ru.beeline.fdmauth.repository.rbac.RbacAuditLogRepository;

import java.time.LocalDateTime;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

@Service
@Slf4j
public class RbacAuditService {

    private static final int MAX_DENY_COUNT = 5;
    private static final int CACHE_MAX_SIZE = 100;
    private static final long CLEANUP_INTERVAL_MS = 60_000L;

    @Autowired
    private RbacAuditLogRepository auditLogRepository;

    private final ConcurrentHashMap<String, AtomicInteger> denyCounts = new ConcurrentHashMap<>();
    private final AtomicLong lastCleanupTime = new AtomicLong(0);

    public void record(Integer userId, String method, String path,
                       String effect, String description, String params) {
        String key = effect + "|" + method + "|" + path;

        if (denyCounts.size() > CACHE_MAX_SIZE) {
            denyCounts.clear();
        }
        int count = denyCounts.computeIfAbsent(key, k -> new AtomicInteger(0)).incrementAndGet();
        if (count >= MAX_DENY_COUNT) {
            return;
        }

        long now = System.currentTimeMillis();
        if (now - lastCleanupTime.get() > CLEANUP_INTERVAL_MS) {
            lastCleanupTime.set(now);
            try {
                auditLogRepository.deleteOlderThan(LocalDateTime.now().minusDays(5));
            } catch (Exception e) {
                log.warn("rbac_audit_log cleanup failed: {}", e.getMessage());
            }
        }

        try {
            auditLogRepository.save(RbacAuditLog.builder()
                    .userId(userId)
                    .method(method)
                    .path(path)
                    .effect(effect)
                    .description(description)
                    .params(params)
                    .ts(LocalDateTime.now())
                    .build());
        } catch (Exception e) {
            log.warn("rbac_audit_log save failed: {}", e.getMessage());
        }
    }
}
