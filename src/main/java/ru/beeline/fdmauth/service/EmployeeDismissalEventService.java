package ru.beeline.fdmauth.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import ru.beeline.fdmauth.client.CxClient;
import ru.beeline.fdmauth.domain.ConsumerErrorLog;
import ru.beeline.fdmauth.dto.EmployeeDismissalEventDTO;
import ru.beeline.fdmauth.repository.ConsumerErrorLogRepository;
import ru.beeline.fdmauth.service.EmployeeDismissalHandler.ReassignIds;

import java.time.Instant;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmployeeDismissalEventService {

    private final EmployeeDismissalHandler dismissalHandler;
    private final ConsumerErrorLogRepository consumerErrorLogRepository;
    private final CxClient cxClient;

    public void handleDto(EmployeeDismissalEventDTO event) {
        ReassignIds ids = dismissalHandler.processAndSave(event);
        if (ids != null) {
            cxClient.reassignOwner(ids.currentUserId(), ids.newUserId());
        }
    }

    public void handleDtoSafe(EmployeeDismissalEventDTO event) {
        String eventId = event != null && event.getMetadata() != null && event.getMetadata().getEventId() != null
                ? event.getMetadata().getEventId()
                : "unknown";
        try {
            handleDto(event);
        } catch (Exception e) {
            log.warn("Employee dismissal event processing failed. eventId={}", eventId, e);
            saveError(eventId, buildErrorMessage(e), null);
        }
    }

    public void saveError(String eventId, String errorMessage, String payload) {
        consumerErrorLogRepository.saveAndFlush(ConsumerErrorLog.builder()
                .eventId(eventId != null && !eventId.isBlank() ? eventId : "unknown")
                .errorMessage(errorMessage)
                .payload(payload)
                .createdAt(Instant.now())
                .build());
    }

    public String buildErrorMessage(Exception e) {
        String msg = e.getMessage();
        if (msg == null || msg.isBlank()) {
            msg = e.getClass().getSimpleName();
        }
        return msg;
    }
}
