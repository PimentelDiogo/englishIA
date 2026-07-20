package com.diogo.gateway.student;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Fronteira GOVERNADA de acesso ao histórico do aluno (ADR-006) — read-only, menor privilégio.
 * Estas são exatamente as "tools" que um MCP server exporia: {@code getWeakVocabulary},
 * {@code getDueVocabulary}. Quando o transporte MCP entrar, troca-se o {@link StudentRepository}
 * por um MCP client aqui — o {@code TutorService} não muda.
 *
 * <p>Fail-soft: DB fora / aluno sem dados → vazio (o tutor segue sem personalização).
 */
@Service
public class StudentHistoryService {

    private static final Logger log = LoggerFactory.getLogger(StudentHistoryService.class);

    private final StudentRepository repo;

    public StudentHistoryService(StudentRepository repo) {
        this.repo = repo;
    }

    // ---- "MCP tools" (read-only) ----

    public List<StudentWord> getWeakVocabulary(String userId, int limit) {
        try {
            return repo.weak(userId, limit);
        } catch (Exception e) {
            log.warn("Histórico do aluno indisponivel (seguindo sem personalização): {}", e.getMessage());
            return List.of();
        }
    }

    public List<StudentWord> getDueVocabulary(String userId, int limit) {
        try {
            return repo.due(userId, limit);
        } catch (Exception e) {
            log.warn("Histórico do aluno indisponivel: {}", e.getMessage());
            return List.of();
        }
    }

    // ---- Sync (o app envia o SRS do Isar) ----

    public void sync(String userId, List<VocabItem> items) {
        for (VocabItem it : items) {
            repo.upsert(userId, it.word(), it.translation(), it.easeFactor(), it.nextReviewEpochMs());
        }
    }

    // ---- Bloco de personalização para o prompt (null se não há sinal) ----

    public String personalizationBlock(String userId, int weakLimit) {
        List<StudentWord> weak = getWeakVocabulary(userId, weakLimit);
        if (weak.isEmpty()) {
            return null;
        }
        String words = weak.stream().map(StudentWord::word).collect(Collectors.joining(", "));
        return "The student currently struggles with these words/expressions: " + words
                + ". Prefer examples that reinforce them, and gently correct related mistakes.";
    }
}
