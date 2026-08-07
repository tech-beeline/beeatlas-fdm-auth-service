/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.repository.rbac;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import ru.beeline.fdmauth.domain.rbac.RbacAuditLog;

import java.time.LocalDateTime;

@Repository
public interface RbacAuditLogRepository extends JpaRepository<RbacAuditLog, Long> {

    @Transactional
    @Modifying
    @Query("DELETE FROM RbacAuditLog r WHERE r.ts < :cutoff")
    void deleteOlderThan(@Param("cutoff") LocalDateTime cutoff);
}
