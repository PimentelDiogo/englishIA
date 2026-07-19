package com.diogo.gateway.llm;

/**
 * Falha ao obter resposta de um provedor de LLM. Carrega uma mensagem honesta,
 * apresentavel ao usuario (nunca vaza stacktrace/detalhe do provedor).
 *
 * <p>Semente do "fallback honesto" do PRD-ai-tutor: quando o tutor nao consegue
 * responder, dizemos isso claramente em vez de inventar.
 */
public class LlmException extends RuntimeException {

    public LlmException(String message, Throwable cause) {
        super(message, cause);
    }
}
