package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.Permission;
import java.util.List;


@Repository
public interface PermissionRepository extends JpaRepository<Permission, Long> {

    List<Permission> findByIdIn(List<Long> idList);
}
