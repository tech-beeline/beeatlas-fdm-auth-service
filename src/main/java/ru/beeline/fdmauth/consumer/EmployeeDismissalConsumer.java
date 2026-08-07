package ru.beeline.fdmauth.consumer;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.avro.generic.GenericRecord;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;
import ru.beeline.fdmauth.dto.EmployeeDismissalEventDTO;
import ru.beeline.fdmauth.service.EmployeeDismissalEventService;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "fdm-auth.kafka.enabled", havingValue = "true", matchIfMissing = true)
public class EmployeeDismissalConsumer {

    private final EmployeeDismissalEventService eventService;

    @KafkaListener(topics = "${spring.kafka.employee-dismissal-topic}")
    public void onMessage(GenericRecord record, Acknowledgment acknowledgment) {
        String eventId = extractEventIdBestEffort(record);
        try {
            eventService.handleDto(toDto(record));
        } catch (Exception e) {
            log.warn("Employee dismissal consumer failed. eventId={}", eventId, e);
            eventService.saveError(eventId, eventService.buildErrorMessage(e), record != null ? record.toString() : null);
        } finally {
            acknowledgment.acknowledge();
        }
    }

    private EmployeeDismissalEventDTO toDto(GenericRecord record) {
        if (record == null) return null;
        EmployeeDismissalEventDTO dto = new EmployeeDismissalEventDTO();

        Object metadataObj = record.get("metadata");
        if (metadataObj instanceof GenericRecord metaRecord) {
            EmployeeDismissalEventDTO.Metadata meta = new EmployeeDismissalEventDTO.Metadata();
            Object eventId = metaRecord.get("event_id");
            meta.setEventId(eventId != null ? eventId.toString() : null);
            dto.setMetadata(meta);
        }

        Object dataObj = record.get("data");
        if (dataObj instanceof GenericRecord dataRecord) {
            EmployeeDismissalEventDTO.Data data = new EmployeeDismissalEventDTO.Data();
            Object id = dataRecord.get("id");
            data.setId(id != null ? Integer.valueOf(id.toString()) : null);
            Object dateOfDismissal = dataRecord.get("date_of_dismissal");
            data.setDateOfDismissal(dateOfDismissal != null ? dateOfDismissal.toString() : null);
            dto.setData(data);
        }

        return dto;
    }

    private static String extractEventIdBestEffort(GenericRecord record) {
        if (record == null) return "unknown";
        try {
            Object metadata = record.get("metadata");
            if (metadata instanceof GenericRecord meta) {
                Object eventId = meta.get("event_id");
                if (eventId != null && !eventId.toString().isBlank()) {
                    return eventId.toString();
                }
            }
        } catch (Exception ignored) {
        }
        return "unknown";
    }

}
