package com.diogo.gateway.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Config do fallback multi-provedor (ADR-002). Claude é o fallback do Gemini.
 * DESABILITADO por padrão; sem conta Anthropic, o gateway roda só com o Gemini.
 *
 * <p>Modelo padrão `claude-opus-4-8` seguindo a orientação da Anthropic (não rebaixar
 * por custo — é decisão do Diogo). Ajustável (ex.: `claude-haiku-4-5`).
 */
@ConfigurationProperties(prefix = "fallback")
public record FallbackProperties(
        boolean enabled,
        String apiKey,
        String model,
        int maxTokens
) {
}
