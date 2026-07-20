package com.diogo.gateway.student;

import com.diogo.gateway.config.PersonalizationProperties;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * API do histórico do aluno (ADR-006): o app sincroniza o SRS; endpoints de leitura
 * espelham as "tools" MCP (read-only) para debug.
 */
@RestController
@RequestMapping("/student")
public class StudentController {

    private final StudentHistoryService history;
    private final PersonalizationProperties props;

    public StudentController(StudentHistoryService history, PersonalizationProperties props) {
        this.history = history;
        this.props = props;
    }

    /** Sync: o app envia o vocabulário/SRS do Isar. */
    @PostMapping("/{userId}/vocabulary")
    public void sync(@PathVariable String userId, @RequestBody List<VocabItem> items) {
        history.sync(userId, items);
    }

    /** Debug/tool: palavras mais fracas do aluno. */
    @GetMapping("/{userId}/weak")
    public List<StudentWord> weak(@PathVariable String userId) {
        return history.getWeakVocabulary(userId, props.weakLimit());
    }

    /** Debug/tool: palavras vencidas para revisão. */
    @GetMapping("/{userId}/due")
    public List<StudentWord> due(@PathVariable String userId) {
        return history.getDueVocabulary(userId, props.weakLimit());
    }
}
