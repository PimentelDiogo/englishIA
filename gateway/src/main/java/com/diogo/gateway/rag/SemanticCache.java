package com.diogo.gateway.rag;

import com.diogo.gateway.config.CacheProperties;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

/**
 * Cache semântico (ADR-004): perguntas quase idênticas ("how do I use make vs do?")
 * respondem do cache, sem gastar o modelo forte. Backed by pgvector — reusa a mesma infra
 * do RAG. Distância de cosseno tight ({@code cache.max-distance}) para evitar falso-hit.
 */
@Component
public class SemanticCache {

    private final JdbcClient jdbc;
    private final CacheProperties props;

    public SemanticCache(JdbcClient jdbc, CacheProperties props) {
        this.jdbc = jdbc;
        this.props = props;
    }

    public void ensureSchema(int dimensions) {
        jdbc.sql("""
                CREATE TABLE IF NOT EXISTS response_cache (
                    id BIGSERIAL PRIMARY KEY,
                    question TEXT NOT NULL,
                    reply TEXT NOT NULL,
                    embedding vector(%d) NOT NULL
                )
                """.formatted(dimensions)).update();
    }

    /** Retorna a resposta cacheada se houver entrada suficientemente similar. */
    public Optional<String> lookup(float[] embedding) {
        List<Hit> hits = jdbc.sql("""
                        SELECT reply, (embedding <=> CAST(:q AS vector)) AS distance
                        FROM response_cache
                        ORDER BY distance ASC
                        LIMIT 1
                        """)
                .param("q", Vectors.toLiteral(embedding))
                .query((rs, n) -> new Hit(rs.getString("reply"), rs.getDouble("distance")))
                .list();
        if (!hits.isEmpty() && hits.get(0).distance() <= props.maxDistance()) {
            return Optional.of(hits.get(0).reply());
        }
        return Optional.empty();
    }

    public void store(float[] embedding, String question, String reply) {
        jdbc.sql("INSERT INTO response_cache (question, reply, embedding) "
                        + "VALUES (:q, :r, CAST(:e AS vector))")
                .param("q", question)
                .param("r", reply)
                .param("e", Vectors.toLiteral(embedding))
                .update();
    }

    private record Hit(String reply, double distance) {
    }
}
