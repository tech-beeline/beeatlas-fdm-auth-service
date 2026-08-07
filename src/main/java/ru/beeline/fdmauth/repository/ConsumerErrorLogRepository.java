package ru.beeline.fdmauth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.beeline.fdmauth.domain.ConsumerErrorLog;

@Repository
public interface ConsumerErrorLogRepository extends JpaRepository<ConsumerErrorLog, Integer> {
}
