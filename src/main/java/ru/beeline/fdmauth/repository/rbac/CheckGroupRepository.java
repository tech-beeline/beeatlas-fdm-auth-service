/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.repository.rbac;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.rbac.CheckGroup;

import java.util.List;

@Repository
public interface CheckGroupRepository extends JpaRepository<CheckGroup, Long> {
    List<CheckGroup> findByGroupId(Integer groupId);
    void deleteByGroupId(Integer groupId);

    @Query("SELECT COALESCE(MAX(c.groupId), 0) FROM CheckGroup c")
    Integer findMaxGroupId();
}
