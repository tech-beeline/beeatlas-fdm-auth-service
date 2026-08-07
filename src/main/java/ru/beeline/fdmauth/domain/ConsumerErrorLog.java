package ru.beeline.fdmauth.domain;
import lombok.*;
import javax.persistence.*;
import java.time.Instant;
@Builder
@Data
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "consumer_error_log", schema = "user_auth")
public class ConsumerErrorLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    @Column(name = "event_id", nullable = false, length = 255)
    private String eventId;
    @Column(name = "error_message", nullable = false, columnDefinition = "TEXT")
    private String errorMessage;
    @Column(name = "payload", columnDefinition = "TEXT")
    private String payload;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}