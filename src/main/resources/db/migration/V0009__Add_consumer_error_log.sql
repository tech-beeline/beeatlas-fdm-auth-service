CREATE TABLE IF NOT EXISTS user_auth.consumer_error_log (
                                                            id              serial4        PRIMARY KEY,
                                                            event_id        VARCHAR(255)   NOT NULL,
    error_message   TEXT           NOT NULL,
    payload         TEXT           NULL,
    created_at      TIMESTAMP      NOT NULL DEFAULT now()
    );

COMMENT ON TABLE user_auth.consumer_error_log IS 'Ошибки обработки Kafka-сообщений консьюмерами fdm-auth';
COMMENT ON COLUMN user_auth.consumer_error_log.event_id IS 'metadata.event_id из Kafka-сообщения';
COMMENT ON COLUMN user_auth.consumer_error_log.error_message IS 'Текст ошибки / HTTP статус + тело';
COMMENT ON COLUMN user_auth.consumer_error_log.payload IS 'Исходное Kafka-сообщение для анализа';
COMMENT ON COLUMN user_auth.consumer_error_log.created_at IS 'Время записи ошибки';

