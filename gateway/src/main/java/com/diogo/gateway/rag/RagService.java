package com.diogo.gateway.rag;

import com.diogo.gateway.config.RagProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Retrieval do RAG (Fase 3): busca HÍBRIDA (dense pgvector + lexical full-text) fundida por
 * RRF (Reciprocal Rank Fusion). Fail-soft: se DB/embeddings falharem, retorna vazio
 * (o tutor segue sem grounding, sem derrubar a request).
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

    /**
     * Chunks relevantes via busca híbrida (dense + lexical) fundida por RRF.
     *
     * @param queryEmbedding embedding da query (dense; pode ser null → só lexical)
     * @param queryText      texto da query (lexical; pode ser vazio → só dense)
     */
    public List<KnowledgeChunk> retrieve(float[] queryEmbedding, String queryText) {
        try {
            List<KnowledgeChunk> dense = queryEmbedding == null ? List.of()
                    : repo.searchDense(queryEmbedding, props.topK()).stream()
                            .filter(c -> c.distance() <= props.maxDistance())
                            .toList();

            List<KnowledgeChunk> lexical = List.of();
            if (props.hybridEnabled() && queryText != null && !queryText.isBlank()) {
                try {
                    lexical = repo.searchLexical(queryText, props.topK());
                } catch (Exception e) {
                    // Coluna full-text ausente (DB antigo) etc.: cai para só dense.
                    log.warn("Busca lexical indisponivel (só dense): {}", e.getMessage());
                }
            }

            if (lexical.isEmpty()) {
                return dense; // sem híbrido: comportamento dense puro
            }
            return reciprocalRankFusion(dense, lexical, props.topK());
        } catch (Exception e) {
            log.warn("RAG indisponivel (seguindo sem grounding): {}", e.getMessage());
            return List.of();
        }
    }

    /**
     * Reciprocal Rank Fusion: score(chunk) = Σ 1/(k + rank) sobre as duas listas.
     * É o "rerank" do híbrido — combina os rankings sem cross-encoder.
     */
    private List<KnowledgeChunk> reciprocalRankFusion(
            List<KnowledgeChunk> dense, List<KnowledgeChunk> lexical, int topK) {
        final int rrfK = 60; // constante padrão do RRF
        Map<String, Double> scores = new LinkedHashMap<>();
        Map<String, KnowledgeChunk> byKey = new LinkedHashMap<>();

        accumulate(dense, rrfK, scores, byKey);
        accumulate(lexical, rrfK, scores, byKey);

        return scores.entrySet().stream()
                .sorted((a, b) -> Double.compare(b.getValue(), a.getValue()))
                .limit(topK)
                .map(e -> byKey.get(e.getKey()))
                .toList();
    }

    private void accumulate(List<KnowledgeChunk> ranked, int rrfK,
                            Map<String, Double> scores, Map<String, KnowledgeChunk> byKey) {
        for (int rank = 0; rank < ranked.size(); rank++) {
            KnowledgeChunk c = ranked.get(rank);
            String key = c.content();
            scores.merge(key, 1.0 / (rrfK + rank + 1), Double::sum);
            byKey.putIfAbsent(key, c);
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
