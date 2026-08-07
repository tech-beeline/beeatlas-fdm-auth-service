package ru.beeline.fdmauth.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@Schema(description = "Событие увольнения сотрудника")
public class EmployeeDismissalEventDTO {

    @JsonProperty("metadata")
    @Schema(description = "Метаданные события")
    private Metadata metadata;

    @JsonProperty("data")
    @Schema(description = "Данные события")
    private Data data;

    @Getter
    @Setter
    @NoArgsConstructor
    @Schema(description = "Метаданные события увольнения")
    public static class Metadata {
        @JsonProperty("event_id")
        @Schema(description = "Идентификатор события", example = "a1b2c3d4-1234-5678-abcd-ef0123456789")
        private String eventId;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @Schema(description = "Данные об уволенном сотруднике")
    public static class Data {
        @JsonProperty("id")
        @Schema(description = "Табельный номер сотрудника", example = "123456")
        private Integer id;

        @JsonProperty("date_of_dismissal")
        @Schema(description = "Дата увольнения в формате YYYY-MM-DD", example = "2025-12-31")
        private String dateOfDismissal;
    }
}
