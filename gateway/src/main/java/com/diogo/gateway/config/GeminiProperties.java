package com.diogo.gateway.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuracao do provedor Gemini (ADR-002 preve troca por fallback no futuro).
 * Chave sempre via env — nunca hardcode (ADR-001).
 */
@ConfigurationProperties(prefix = "gemini")
public record GeminiProperties(
        String apiKey,
        String model,
        String classifierModel,
        String baseUrl,
        double inputPricePerMillion,
        double outputPricePerMillion
) {
}
