package com.diogo.gateway.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Config do model router (ADR-004). O modelo "forte" e {@code gemini.model}; o "barato"
 * e este {@code cheapModel}.
 */
@ConfigurationProperties(prefix = "router")
public record RouterProperties(boolean enabled, String cheapModel) {
}
