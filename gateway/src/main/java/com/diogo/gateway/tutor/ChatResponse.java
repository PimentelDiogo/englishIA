package com.diogo.gateway.tutor;

/**
 * Saida do endpoint /tutor/chat. Expoe o uso (tokens/custo/latencia) junto da
 * resposta — assim o consumo fica visivel para o app e para a demo de entrevista.
 */
public record ChatResponse(String reply, Usage usage) {

    public record Usage(
            String model,
            int promptTokens,
            int outputTokens,
            int totalTokens,
            double estimatedCostUsd,
            long latencyMs
    ) {
    }
}
