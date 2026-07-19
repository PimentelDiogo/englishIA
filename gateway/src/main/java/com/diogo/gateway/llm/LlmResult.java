package com.diogo.gateway.llm;

/**
 * Resultado normalizado de uma chamada a um LLM — independente do provedor.
 * Quando entrar o fallback (ADR-002), Claude/OpenAI tambem retornam este tipo.
 */
public record LlmResult(
        String provider,
        String model,
        String text,
        int promptTokens,
        int outputTokens,
        int totalTokens
) {
}
