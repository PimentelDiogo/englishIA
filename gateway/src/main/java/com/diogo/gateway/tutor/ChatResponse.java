package com.diogo.gateway.tutor;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * Saida do endpoint /tutor/chat. Expoe o uso (tokens/custo/latencia) e, quando um
 * guardrail atua, sinaliza {@code blocked} + {@code reason} (o app pode tratar/telemetrar).
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ChatResponse(String reply, boolean blocked, String reason, Usage usage) {

    public record Usage(
            String model,
            int promptTokens,
            int outputTokens,
            int totalTokens,
            double estimatedCostUsd,
            long latencyMs
    ) {
        /** Uso "zero" — para respostas bloqueadas na entrada (nenhum token do modelo forte gasto). */
        public static Usage none() {
            return new Usage("none", 0, 0, 0, 0.0, 0);
        }
    }
}
