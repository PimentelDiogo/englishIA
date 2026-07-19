package com.diogo.gateway.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Config do RAG (Fase 3 / ADR-003).
 *
 * @param embeddingModel      modelo de embeddings do Gemini (ex.: text-embedding-004)
 * @param embeddingDimensions dimensao do vetor (deve casar com a coluna vector(N))
 * @param topK                quantos chunks recuperar
 * @param maxDistance         distancia de cosseno maxima para um chunk ser relevante
 * @param seedOnStartup       semear a base no boot (idempotente)
 */
@ConfigurationProperties(prefix = "rag")
public record RagProperties(
        String embeddingModel,
        int embeddingDimensions,
        int topK,
        double maxDistance,
        boolean seedOnStartup,
        boolean hybridEnabled
) {
}
