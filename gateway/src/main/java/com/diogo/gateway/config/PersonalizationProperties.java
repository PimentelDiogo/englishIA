package com.diogo.gateway.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Config da personalização por histórico do aluno (ADR-006).
 *
 * @param enabled   liga/desliga a injeção de personalização no prompt
 * @param weakLimit quantas palavras "fracas" puxar para o contexto
 */
@ConfigurationProperties(prefix = "personalization")
public record PersonalizationProperties(boolean enabled, int weakLimit) {
}
