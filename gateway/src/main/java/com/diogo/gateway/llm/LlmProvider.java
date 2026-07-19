package com.diogo.gateway.llm;

import java.util.List;

/**
 * Provedor de LLM abstrato (ADR-002). Gemini é o primário; Claude o fallback.
 * A abstração permite o {@link com.diogo.gateway.llm.ModelRouter} e o fallback
 * tratarem qualquer provedor de forma uniforme.
 */
public interface LlmProvider {

    /** Nome curto do provedor (ex.: "gemini", "claude") — vira dimensão de métrica. */
    String name();

    LlmResult generate(String model, String systemInstruction, List<LlmTurn> turns);
}
