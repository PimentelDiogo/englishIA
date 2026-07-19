package com.diogo.gateway.llm;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;

/**
 * DTOs de request/response da API generateContent do Gemini (v1beta).
 * Mantidos internos ao pacote llm — o resto do gateway nao conhece o formato do provedor.
 */
final class GeminiDtos {

    private GeminiDtos() {
    }

    // ---------- Request ----------
    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Request(List<Content> contents, Content systemInstruction) {
    }

    // role: "user" | "model" nas turns da conversa; null (omitido) na systemInstruction.
    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Content(String role, List<Part> parts) {
    }

    record Part(String text) {
    }

    // ---------- Response ----------
    record Response(List<Candidate> candidates, UsageMetadata usageMetadata) {
    }

    record Candidate(Content content) {
    }

    record UsageMetadata(Integer promptTokenCount, Integer candidatesTokenCount, Integer totalTokenCount) {
    }
}
