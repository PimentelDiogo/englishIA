package com.diogo.gateway.tutor;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * Saida do endpoint /tutor/chat. Expoe o uso (tokens/custo/latencia); sinaliza {@code blocked}
 * quando um guardrail atua e {@code cached} quando a resposta veio do cache semantico.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ChatResponse(String reply, boolean blocked, String reason, boolean cached, Usage usage) {

    public record Usage(
            String model,
            int promptTokens,
            int outputTokens,
            int totalTokens,
            double estimatedCostUsd,
            long latencyMs
    ) {
        /** Uso "zero" — respostas bloqueadas na entrada ou servidas do cache (0 token do forte). */
        public static Usage none() {
            return new Usage("none", 0, 0, 0, 0.0, 0);
        }
    }
}
