package com.diogo.gateway.rag;

import com.diogo.gateway.config.RagProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Retrieval do RAG (Fase 3): embute a query, busca no pgvector e devolve os chunks
 * relevantes (abaixo do limiar de distancia). Fail-soft: se DB/embeddings falharem,
 * retorna vazio (o tutor segue sem grounding, sem derrubar a request).
 */
@Service
public class RagService {

    private static final Logger log = LoggerFactory.getLogger(RagService.class);

    private final GeminiEmbeddingClient embeddings;
    private final KnowledgeRepository repo;
    private final RagProperties props;

    public RagService(GeminiEmbeddingClient embeddings, KnowledgeRepository repo, RagProperties props) {
        this.embeddings = embeddings;
        this.repo = repo;
        this.props = props;
    }

    /** Embedding da query (null em caso de falha) — computado UMA vez e reusado (cache + RAG). */
    public float[] embedQuery(String query) {
        try {
            return embeddings.embed(query);
        } catch (Exception e) {
            log.warn("Embedding indisponivel: {}", e.getMessage());
            return null;
        }
    }

    /** Chunks relevantes para um embedding ja calculado (vazio se null ou nada relevante). */
    public List<KnowledgeChunk> retrieve(float[] queryEmbedding) {
        if (queryEmbedding == null) {
            return List.of();
        }
        try {
            return repo.search(queryEmbedding, props.topK()).stream()
                    .filter(c -> c.distance() <= props.maxDistance())
                    .toList();
        } catch (Exception e) {
            log.warn("RAG indisponivel (seguindo sem grounding): {}", e.getMessage());
            return List.of();
        }
    }

    /** Monta o bloco de contexto para injetar no prompt do tutor (null se vazio). */
    public String toContextBlock(List<KnowledgeChunk> chunks) {
        if (chunks.isEmpty()) {
            return null;
        }
        StringBuilder sb = new StringBuilder(
                "Use ONLY the following reference knowledge to justify grammar/vocabulary. "
                        + "If it is not enough, say you are not sure.\n");
        for (KnowledgeChunk c : chunks) {
            sb.append("- [").append(c.category()).append("] ").append(c.content()).append('\n');
        }
        return sb.toString();
    }
}
