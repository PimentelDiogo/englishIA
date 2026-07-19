package com.diogo.gateway.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Config dos guardrails (ADR-005). Os checks baseados em LLM usam o modelo BARATO
 * (gemini.classifier-model) — sem SaaS externo, sem conta nova.
 */
@ConfigurationProperties(prefix = "guardrail")
public record GuardrailProperties(
        int maxInputLength,
        boolean llmChecksEnabled
) {
}
