package com.diogo.gateway.rag;

import com.diogo.gateway.config.RagProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * Semeia a base de conhecimento no boot (idempotente). Precisa de DB + GEMINI_API_KEY.
 * Fail-soft: se o DB estiver fora ou faltar chave, apenas loga e segue (o gateway sobe
 * mesmo assim — inclusive para o teste de contexto sem DB).
 *
 * <p>Conteudo minimo de laboratorio (gramatica + phrasal verbs). Diogo ajusta/expande depois.
 */
@Component
public class KnowledgeSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(KnowledgeSeeder.class);

    // Seed curado (pequeno de proposito). category -> texto.
    private static final List<Map.Entry<String, String>> SEED = List.of(
            Map.entry("grammar", "Present perfect (have/has + past participle) links a past action to the present: 'I have finished my homework.' Use it for experiences and unfinished time."),
            Map.entry("grammar", "Use 'since' with a point in time and 'for' with a duration: 'since 2020', 'for three years'."),
            Map.entry("grammar", "Countable nouns take 'a/an' and can be plural ('an apple'); uncountable nouns do not ('water', not 'a water')."),
            Map.entry("grammar", "Third person singular in present simple adds -s: 'She works', 'He goes'."),
            Map.entry("grammar", "'make' vs 'do': use 'make' for creating/producing ('make a decision'), 'do' for tasks/activities ('do homework')."),
            Map.entry("phrasal_verb", "'give up' = to quit or stop trying: 'Don't give up on your English.'"),
            Map.entry("phrasal_verb", "'look up' = to search for information: 'I looked up the word in the dictionary.'"),
            Map.entry("phrasal_verb", "'run out of' = to have no more of something: 'We ran out of time.'"),
            Map.entry("phrasal_verb", "'get along with' = to have a good relationship: 'I get along with my classmates.'"),
            Map.entry("phrasal_verb", "'bring up' = to raise a topic: 'She brought up an interesting point.'")
    );

    private final KnowledgeRepository repo;
    private final SemanticCache cache;
    private final GeminiEmbeddingClient embeddings;
    private final RagProperties props;

    public KnowledgeSeeder(KnowledgeRepository repo, SemanticCache cache,
                           GeminiEmbeddingClient embeddings, RagProperties props) {
        this.repo = repo;
        this.cache = cache;
        this.embeddings = embeddings;
        this.props = props;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!props.seedOnStartup()) {
            return;
        }
        try {
            repo.ensureSchema(props.embeddingDimensions());
            cache.ensureSchema(props.embeddingDimensions()); // schema do cache semântico (ADR-004)
            if (repo.count() > 0) {
                log.info("Base de conhecimento ja populada — seed ignorado.");
                return;
            }
            for (Map.Entry<String, String> e : SEED) {
                repo.save(e.getValue(), e.getKey(), embeddings.embed(e.getValue()));
            }
            log.info("Base de conhecimento semeada: {} chunks.", SEED.size());
        } catch (Exception e) {
            // DB fora / sem chave: nao derruba o boot.
            log.warn("Seed do RAG pulado (DB/embeddings indisponivel): {}", e.getMessage());
        }
    }
}
