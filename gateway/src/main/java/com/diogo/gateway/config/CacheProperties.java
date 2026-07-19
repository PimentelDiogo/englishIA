package com.diogo.gateway.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Config do cache semântico (ADR-004).
 *
 * @param enabled     liga/desliga o cache
 * @param maxDistance distancia de cosseno maxima para considerar HIT (tight — perguntas
 *                    quase idênticas). 0 = idêntico.
 */
@ConfigurationProperties(prefix = "cache")
public record CacheProperties(boolean enabled, double maxDistance) {
}
