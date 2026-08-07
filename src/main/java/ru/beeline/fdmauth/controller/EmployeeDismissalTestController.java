package ru.beeline.fdmauth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.beeline.fdmauth.annotation.ApiErrorCodes;
import ru.beeline.fdmauth.dto.EmployeeDismissalEventDTO;
import ru.beeline.fdmauth.service.EmployeeDismissalEventService;

@Slf4j
@RestController
@RequestMapping("/api/test/v1/employee-dismissal")
@Tag(name = "Тестирование", description = "Тестовые эндпоинты для отладки и разработки")
@RequiredArgsConstructor
public class EmployeeDismissalTestController {

    private final EmployeeDismissalEventService employeeDismissalEventService;

    @ApiErrorCodes({400, 500})
    @PostMapping(value = "/trigger", consumes = "application/json")
    @Operation(
            summary = "Тестовый триггер события увольнения сотрудника",
            description = "Эмулирует получение Kafka-события увольнения. Пример тела запроса:\n\n" +
                    "```json\n" +
                    "{\n" +
                    "  \"metadata\": {\n" +
                    "    \"event_id\": \"a1b2c3d4-1234-5678-abcd-ef0123456789\"\n" +
                    "  },\n" +
                    "  \"data\": {\n" +
                    "    \"id\": 123456,\n" +
                    "    \"date_of_dismissal\": \"2025-12-31\"\n" +
                    "  }\n" +
                    "}\n" +
                    "```"
    )
    public ResponseEntity<Void> trigger(@RequestBody EmployeeDismissalEventDTO event) {
        log.info("Test trigger: employee dismissal event received, employeeId={}",
                event.getData() != null ? event.getData().getId() : null);
        employeeDismissalEventService.handleDtoSafe(event);
        return ResponseEntity.ok().build();
    }
}
