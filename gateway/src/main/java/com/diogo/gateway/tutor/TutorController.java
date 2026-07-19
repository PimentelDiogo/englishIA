package com.diogo.gateway.tutor;

import com.diogo.gateway.llm.GeminiClient;
import com.diogo.gateway.llm.LlmResult;
import com.diogo.gateway.observability.LlmMetrics;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Porta de entrada do AI Tutor (ADR-001). Nesta Fase 1 apenas repassa ao Gemini
 * server-side e mede o consumo. Guardrails (Fase 2), RAG (Fase 3), router/cache
 * (Fase 4) e fallback (Fase 5) entram como camadas antes/depois desta chamada.
 */
@RestController
@RequestMapping("/tutor")
public class TutorController {

    private static final String SYSTEM_TUTOR = """
            You are English IA, a friendly and patient English tutor.
            Reply in natural English. Keep answers concise and encouraging.
            If the student makes a grammar mistake, gently point it out and show the correction.
            """;

    private final GeminiClient gemini;
    private final LlmMetrics metrics;

    public TutorController(GeminiClient gemini, LlmMetrics metrics) {
        this.gemini = gemini;
        this.metrics = metrics;
    }

    @PostMapping("/chat")
    public ChatResponse chat(@RequestBody ChatRequest request) {
        long start = System.nanoTime();
        LlmResult result = gemini.generate(SYSTEM_TUTOR, request.message());
        long latencyMs = (System.nanoTime() - start) / 1_000_000;

        double cost = metrics.record("chat", result, latencyMs);

        return new ChatResponse(
                result.text(),
                new ChatResponse.Usage(
                        result.model(),
                        result.promptTokens(),
                        result.outputTokens(),
                        result.totalTokens(),
                        cost,
                        latencyMs
                )
        );
    }
}
