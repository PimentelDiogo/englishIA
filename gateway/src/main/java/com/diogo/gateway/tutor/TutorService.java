package com.diogo.gateway.tutor;

import com.diogo.gateway.guardrail.GroundingChecker;
import com.diogo.gateway.guardrail.GuardrailChain;
import com.diogo.gateway.guardrail.GuardrailResult;
import com.diogo.gateway.llm.GeminiClient;
import com.diogo.gateway.llm.LlmResult;
import com.diogo.gateway.llm.LlmTurn;
import com.diogo.gateway.observability.LlmMetrics;
import com.diogo.gateway.rag.KnowledgeChunk;
import com.diogo.gateway.rag.RagService;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * Orquestra o fluxo do tutor: guardrails de entrada → RAG (grounding) → LLM →
 * guardrails de saida → checagem de grounding (anti-alucinacao). ADR-001/004/005 + Fase 3.
 */
@Service
public class TutorService {

    private static final String SYSTEM_TUTOR = """
            You are English IA, a friendly and patient English tutor.
            Reply in natural English. Keep answers concise and encouraging.
            If the student makes a grammar mistake, gently point it out and show the correction.
            """;

    private final GeminiClient gemini;
    private final GuardrailChain guardrails;
    private final GroundingChecker grounding;
    private final RagService rag;
    private final LlmMetrics metrics;

    public TutorService(GeminiClient gemini, GuardrailChain guardrails, GroundingChecker grounding,
                        RagService rag, LlmMetrics metrics) {
        this.gemini = gemini;
        this.guardrails = guardrails;
        this.grounding = grounding;
        this.rag = rag;
        this.metrics = metrics;
    }

    public ChatResponse chat(ChatRequest request) {
        // 1) Input guardrails — barram ANTES de gastar o modelo forte.
        GuardrailResult in = guardrails.checkInput(request.message());
        if (!in.allowed()) {
            metrics.recordGuardrailBlock("input", in.code());
            return new ChatResponse(in.message(), true, in.code(), ChatResponse.Usage.none());
        }

        // 2) RAG — recupera conhecimento relevante e injeta no prompt (grounding).
        List<KnowledgeChunk> chunks = rag.retrieve(request.message());
        String context = rag.toContextBlock(chunks);
        String system = context == null ? SYSTEM_TUTOR : SYSTEM_TUTOR + "\n\n" + context;

        // 3) Monta a conversa (multi-turn) e chama o LLM forte.
        var turns = new ArrayList<LlmTurn>();
        if (request.history() != null) {
            for (ChatRequest.Turn t : request.history()) {
                turns.add(new LlmTurn(t.role(), t.text()));
            }
        }
        turns.add(new LlmTurn("user", request.message()));

        long start = System.nanoTime();
        LlmResult result = gemini.generate(system, List.copyOf(turns));
        long latencyMs = (System.nanoTime() - start) / 1_000_000;
        double cost = metrics.record("chat", result, latencyMs);

        var usage = new ChatResponse.Usage(result.model(), result.promptTokens(),
                result.outputTokens(), result.totalTokens(), cost, latencyMs);

        // 4) Output guardrails — moderacao.
        GuardrailResult out = guardrails.checkOutput(request.message(), result.text());
        if (!out.allowed()) {
            metrics.recordGuardrailBlock("output", out.code());
            return new ChatResponse(out.message(), true, out.code(), usage);
        }

        // 5) Grounding (anti-alucinacao) — so quando houve contexto do RAG.
        GuardrailResult grounded = grounding.check(result.text(), context);
        if (!grounded.allowed()) {
            metrics.recordGuardrailBlock("output", grounded.code());
            return new ChatResponse(grounded.message(), true, grounded.code(), usage);
        }

        return new ChatResponse(result.text(), false, null, usage);
    }
}
