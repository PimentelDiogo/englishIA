package com.diogo.gateway.rag;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Vector store no Postgres + pgvector (ADR-003). Usa Spring JDBC direto (sem Hibernate)
 * para lidar com o tipo `vector` de forma simples: o embedding vai como literal
 * '[v1,v2,...]' com CAST(... AS vector).
 */
@Repository
public class KnowledgeRepository {

    private final JdbcClient jdbc;

    public KnowledgeRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /** Cria extensao, tabela e o índice full-text (idempotente). Chamada pelo seeder no boot. */
    public void ensureSchema(int dimensions) {
        jdbc.sql("CREATE EXTENSION IF NOT EXISTS vector").update();
        jdbc.sql("""
                CREATE TABLE IF NOT EXISTS knowledge_chunk (
                    id BIGSERIAL PRIMARY KEY,
                    content TEXT NOT NULL,
                    category VARCHAR(64) NOT NULL,
                    embedding vector(%d) NOT NULL
                )
                """.formatted(dimensions)).update();
        // Coluna full-text gerada + índice GIN para a busca lexical (BM25-like) do híbrido.
        jdbc.sql("""
                ALTER TABLE knowledge_chunk ADD COLUMN IF NOT EXISTS content_tsv tsvector
                    GENERATED ALWAYS AS (to_tsvector('english', content)) STORED
                """).update();
        jdbc.sql("CREATE INDEX IF NOT EXISTS knowledge_chunk_tsv_idx "
                + "ON knowledge_chunk USING GIN (content_tsv)").update();
    }

    public long count() {
        return jdbc.sql("SELECT COUNT(*) FROM knowledge_chunk").query(Long.class).single();
    }

    public void save(String content, String category, float[] embedding) {
        jdbc.sql("INSERT INTO knowledge_chunk (content, category, embedding) "
                        + "VALUES (:c, :cat, CAST(:e AS vector))")
                .param("c", content)
                .param("cat", category)
                .param("e", Vectors.toLiteral(embedding))
                .update();
    }

    /** Busca dense por similaridade de cosseno (operador <=>). Ordena por proximidade. */
    public List<KnowledgeChunk> searchDense(float[] query, int k) {
        return jdbc.sql("""
                        SELECT content, category, (embedding <=> CAST(:q AS vector)) AS distance
                        FROM knowledge_chunk
                        ORDER BY distance ASC
                        LIMIT :k
                        """)
                .param("q", Vectors.toLiteral(query))
                .param("k", k)
                .query((rs, n) -> new KnowledgeChunk(
                        rs.getString("content"),
                        rs.getString("category"),
                        rs.getDouble("distance")))
                .list();
    }

    /**
     * Busca lexical (BM25-like) via full-text search do Postgres. Ordena por ts_rank_cd.
     * O `distance` retornado é 0.0 (não usado): o híbrido funde por ordem de ranking (RRF).
     */
    public List<KnowledgeChunk> searchLexical(String queryText, int k) {
        return jdbc.sql("""
                        SELECT content, category, 0.0 AS distance
                        FROM knowledge_chunk
                        WHERE content_tsv @@ websearch_to_tsquery('english', :q)
                        ORDER BY ts_rank_cd(content_tsv, websearch_to_tsquery('english', :q)) DESC
                        LIMIT :k
                        """)
                .param("q", queryText)
                .param("k", k)
                .query((rs, n) -> new KnowledgeChunk(
                        rs.getString("content"),
                        rs.getString("category"),
                        rs.getDouble("distance")))
                .list();
    }
}
