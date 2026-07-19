package com.diogo.gateway.tutor;

import com.diogo.gateway.rag.KnowledgeChunk;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Porta de entrada do AI Tutor (ADR-001). Fino de proposito: o fluxo (guardrails →
 * LLM → guardrails) vive no {@link TutorService}.
 */
@RestController
@RequestMapping("/tutor")
public class TutorController {

    private final TutorService tutor;

    public TutorController(TutorService tutor) {
        this.tutor = tutor;
    }

    @PostMapping("/chat")
    public ChatResponse chat(@RequestBody ChatRequest request) {
        return tutor.chat(request);
    }

    /** Endpoint de eval/debug: retorna os chunks recuperados (busca híbrida) para a query. */
    @PostMapping("/retrieve")
    public List<KnowledgeChunk> retrieve(@RequestBody ChatRequest request) {
        return tutor.retrieveContext(request.message());
    }
}
