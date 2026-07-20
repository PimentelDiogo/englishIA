package com.diogo.gateway.tutor;

import com.diogo.gateway.config.CacheProperties;
import com.diogo.gateway.guardrail.GroundingChecker;
import com.diogo.gateway.guardrail.GuardrailChain;
import com.diogo.gateway.guardrail.GuardrailResult;
import com.diogo.gateway.llm.LlmResult;
import com.diogo.gateway.llm.LlmTurn;
import com.diogo.gateway.llm.ModelRouter;
import com.diogo.gateway.llm.ResilientLlmService;
import com.diogo.gateway.config.PersonalizationProperties;
import com.diogo.gateway.observability.LlmMetrics;
import com.diogo.gateway.rag.KnowledgeChunk;
import com.diogo.gateway.rag.RagService;
import com.diogo.gateway.rag.SemanticCache;
import com.diogo.gateway.student.StudentHistoryService;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Orquestra o fluxo do tutor: input guardrails → cache semântico → RAG (grounding) →
 * model router → LLM → output guardrails → grounding check.
 * Cobre ADR-001/003/004/005 + Fases 1–4.
 */
@Service
public class TutorService {

    private static final String SYSTEM_TUTOR = """
            You are English IA, a friendly and patient English tutor.
            Reply in natural English. Keep answers concise and encouraging.
            If the student makes a grammar mistake, gently point it out and show the correction.
            """;

    private final ResilientLlmService llm;
    private final ModelRouter router;
    private final GuardrailChain guardrails;
    private final GroundingChecker grounding;
    private final RagService rag;
    private final SemanticCache cache;
    private final CacheProperties cacheProps;
    private final StudentHistoryService students;
    private final PersonalizationProperties personalizationProps;
    private final LlmMetrics metrics;

    public TutorService(ResilientLlmService llm, ModelRouter router, GuardrailChain guardrails,
                        GroundingChecker grounding, RagService rag, SemanticCache cache,
                        CacheProperties cacheProps, StudentHistoryService students,
                        PersonalizationProperties personalizationProps, LlmMetrics metrics) {
        this.llm = llm;
        this.router = router;
        this.guardrails = guardrails;
        this.grounding = grounding;
        this.rag = rag;
        this.cache = cache;
        this.cacheProps = cacheProps;
        this.students = students;
        this.personalizationProps = personalizationProps;
        this.metrics = metrics;
    }

    /**
     * Recupera os chunks de contexto para uma pergunta (busca híbrida). Endpoint de
     * eval/debug — usado pelo harness RAGAS para medir grounding.
     */
    public List<KnowledgeChunk> retrieveContext(String message) {
        return rag.retrieve(rag.embedQuery(message), message);
    }

    public ChatResponse chat(ChatRequest request) {
        // 1) Input guardrails — barram ANTES de gastar o modelo forte.
        GuardrailResult in = guardrails.checkInput(request.message());
        if (!in.allowed()) {
            metrics.recordGuardrailBlock("input", in.code());
            return new ChatResponse(in.message(), true, in.code(), false, ChatResponse.Usage.none());
        }

        // Cacheável só sem histórico (pergunta isolada). Embedding calculado UMA vez (cache + RAG).
        boolean cacheable = cacheProps.enabled()
                && (request.history() == null || request.history().isEmpty());
        float[] embedding = rag.embedQuery(request.message());

        // 2) Cache semântico — perguntas quase idênticas respondem do cache (0 token do forte).
        if (cacheable && embedding != null) {
            Optional<String> hit = safeCacheLookup(embedding);
            if (hit.isPresent()) {
                metrics.recordCache(true);
                return new ChatResponse(hit.get(), false, null, true, ChatResponse.Usage.none());
            }
            metrics.recordCache(false);
        }

        // 3) RAG — busca híbrida (dense + lexical) e injeta no prompt (grounding).
        List<KnowledgeChunk> chunks = rag.retrieve(embedding, request.message());
        String context = rag.toContextBlock(chunks);

        // 3b) Personalização (ADR-006) — histórico do aluno via fronteira governada.
        String personalization = null;
        if (personalizationProps.enabled() && request.userId() != null && !request.userId().isBlank()) {
            personalization = students.personalizationBlock(request.userId(), personalizationProps.weakLimit());
        }

        StringBuilder sys = new StringBuilder(SYSTEM_TUTOR);
        if (context != null) {
            sys.append("\n\n").append(context);
        }
        if (personalization != null) {
            sys.append("\n\n").append(personalization);
        }
        String system = sys.toString();

        // 4) Model router — pergunta nuançada (tem contexto) → forte; casual → barato (ADR-004).
        String model = router.pickModel(!chunks.isEmpty());
        metrics.recordRoute(model);

        var turns = new ArrayList<LlmTurn>();
        if (request.history() != null) {
            for (ChatRequest.Turn t : request.history()) {
                turns.add(new LlmTurn(t.role(), t.text()));
            }
        }
        turns.add(new LlmTurn("user", request.message()));

        long start = System.nanoTime();
        LlmResult result = llm.generate(model, system, List.copyOf(turns));
        long latencyMs = (System.nanoTime() - start) / 1_000_000;
        double cost = metrics.record("chat", result, latencyMs);

        var usage = new ChatResponse.Usage(result.model(), result.promptTokens(),
                result.outputTokens(), result.totalTokens(), cost, latencyMs);

        // 5) Output guardrails — moderação.
        GuardrailResult out = guardrails.checkOutput(request.message(), result.text());
        if (!out.allowed()) {
            metrics.recordGuardrailBlock("output", out.code());
            return new ChatResponse(out.message(), true, out.code(), false, usage);
        }

        // 6) Grounding (anti-alucinação) — só quando houve contexto do RAG.
        GuardrailResult grounded = grounding.check(result.text(), context);
        if (!grounded.allowed()) {
            metrics.recordGuardrailBlock("output", grounded.code());
            return new ChatResponse(grounded.message(), true, grounded.code(), false, usage);
        }

        // 7) Popula o cache para próximas perguntas iguais.
        if (cacheable && embedding != null) {
            safeCacheStore(embedding, request.message(), result.text());
        }
        return new ChatResponse(result.text(), false, null, false, usage);
    }

    private Optional<String> safeCacheLookup(float[] embedding) {
        try {
            return cache.lookup(embedding);
        } catch (Exception e) {
            return Optional.empty(); // cache fora não pode quebrar a request
        }
    }

    private void safeCacheStore(float[] embedding, String question, String reply) {
        try {
            cache.store(embedding, question, reply);
        } catch (Exception ignored) {
            // best-effort
        }
    }
}
