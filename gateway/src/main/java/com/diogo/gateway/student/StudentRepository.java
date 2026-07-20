package com.diogo.gateway.student;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Store do histórico/SRS do aluno no Postgres (ADR-006). Reusa a infra do ADR-003.
 * O app sincroniza o SRS do Isar para cá; o {@link StudentHistoryService} lê daqui.
 */
@Repository
public class StudentRepository {

    private final JdbcClient jdbc;

    public StudentRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    public void ensureSchema() {
        jdbc.sql("""
                CREATE TABLE IF NOT EXISTS student_vocabulary (
                    id BIGSERIAL PRIMARY KEY,
                    user_id VARCHAR(128) NOT NULL,
                    word TEXT NOT NULL,
                    translation TEXT,
                    ease_factor DOUBLE PRECISION NOT NULL DEFAULT 2.5,
                    next_review_date TIMESTAMPTZ,
                    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                    UNIQUE (user_id, word)
                )
                """).update();
    }

    /** Upsert de um item de vocabulário do aluno (idempotente por user_id + word). */
    public void upsert(String userId, String word, String translation,
                       double easeFactor, long nextReviewEpochMs) {
        jdbc.sql("""
                        INSERT INTO student_vocabulary
                            (user_id, word, translation, ease_factor, next_review_date)
                        VALUES (:u, :w, :t, :e, to_timestamp(:ms / 1000.0))
                        ON CONFLICT (user_id, word) DO UPDATE SET
                            translation = EXCLUDED.translation,
                            ease_factor = EXCLUDED.ease_factor,
                            next_review_date = EXCLUDED.next_review_date,
                            updated_at = now()
                        """)
                .param("u", userId).param("w", word).param("t", translation)
                .param("e", easeFactor).param("ms", nextReviewEpochMs)
                .update();
    }

    /** Palavras que o aluno mais erra (menor ease_factor SM-2). */
    public List<StudentWord> weak(String userId, int limit) {
        return jdbc.sql("""
                        SELECT word, translation, ease_factor
                        FROM student_vocabulary
                        WHERE user_id = :u
                        ORDER BY ease_factor ASC
                        LIMIT :k
                        """)
                .param("u", userId).param("k", limit)
                .query((rs, n) -> new StudentWord(
                        rs.getString("word"), rs.getString("translation"), rs.getDouble("ease_factor")))
                .list();
    }

    /** Palavras vencidas para revisão (nextReviewDate no passado). */
    public List<StudentWord> due(String userId, int limit) {
        return jdbc.sql("""
                        SELECT word, translation, ease_factor
                        FROM student_vocabulary
                        WHERE user_id = :u AND next_review_date <= now()
                        ORDER BY next_review_date ASC
                        LIMIT :k
                        """)
                .param("u", userId).param("k", limit)
                .query((rs, n) -> new StudentWord(
                        rs.getString("word"), rs.getString("translation"), rs.getDouble("ease_factor")))
                .list();
    }
}
