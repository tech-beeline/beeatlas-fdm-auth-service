/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.repository.rbac;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.rbac.CheckType;

@Repository
public interface CheckTypeRepository extends JpaRepository<CheckType, Long> {
}
