package com.diogo.gateway.llm;

import com.diogo.gateway.config.GeminiProperties;
import com.diogo.gateway.config.RouterProperties;
import org.springframework.stereotype.Component;

/**
 * Roteamento por complexidade (ADR-004), rule-based (sem LLM decidindo — barato/previsivel).
 *
 * <p>Sinal usado: se o RAG recuperou contexto de gramatica/vocabulario, e uma pergunta
 * nuancada → modelo FORTE. Caso contrario (diálogo casual) → modelo BARATO. Reusa um sinal
 * que ja existe (o retrieval), sem custo extra.
 */
@Component
public class ModelRouter {

    private final GeminiProperties gemini;
    private final RouterProperties props;

    public ModelRouter(GeminiProperties gemini, RouterProperties props) {
        this.gemini = gemini;
        this.props = props;
    }

    /** @param hasGrammarContext true se o RAG achou contexto relevante para a mensagem. */
    public String pickModel(boolean hasGrammarContext) {
        if (!props.enabled()) {
            return gemini.model();
        }
        return hasGrammarContext ? gemini.model() : props.cheapModel();
    }
}
