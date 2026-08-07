/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.util.StringUtils;

import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

public class FdmAuthKafkaEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {

    private static final String[] AUTOCONFIG_EXCLUDES_WHEN_DISABLED = {
            "org.springframework.boot.autoconfigure.kafka.KafkaAutoConfiguration",
            "org.springframework.boot.actuate.autoconfigure.metrics.kafka.KafkaMetricsAutoConfiguration",
            "org.springframework.boot.autoconfigure.kafka.streams.KafkaStreamsAutoConfiguration",
    };

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        if (environment.getProperty("fdm-auth.kafka.enabled", Boolean.class, Boolean.TRUE)) {
            return;
        }
        Set<String> excludes = new LinkedHashSet<>();
        String existing = environment.getProperty("spring.autoconfigure.exclude");
        if (StringUtils.hasText(existing)) {
            for (String part : StringUtils.commaDelimitedListToStringArray(existing)) {
                if (StringUtils.hasText(part)) {
                    excludes.add(part.trim());
                }
            }
        }
        for (String autoConfig : AUTOCONFIG_EXCLUDES_WHEN_DISABLED) {
            excludes.add(autoConfig);
        }
        environment.getPropertySources().addFirst(new MapPropertySource(
                "fdmAuthKafkaDisabled",
                Map.of("spring.autoconfigure.exclude", String.join(",", excludes))));
    }

    @Override
    public int getOrder() {
        return Ordered.LOWEST_PRECEDENCE;
    }
}
