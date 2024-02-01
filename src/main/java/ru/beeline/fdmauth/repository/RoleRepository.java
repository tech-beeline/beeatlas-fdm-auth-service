package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.Role;
import java.util.List;


@Repository
public interface RoleRepository extends JpaRepository<Role, Long> {
    Role findRoleByName(String name);
    List<Role> findByIdIn(List<Long> idList);
}
