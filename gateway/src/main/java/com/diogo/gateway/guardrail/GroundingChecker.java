package com.diogo.gateway.guardrail;

import com.diogo.gateway.config.GuardrailProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import tools.jackson.databind.JsonNode;

/**
 * Anti-alucinacao (Fase 3): verifica se a resposta do tutor esta FUNDAMENTADA no contexto
 * recuperado pelo RAG (faithfulness-lite via flash-lite). Fecha o gancho de "output
 * guardrail de grounding" prometido na Fase 2.
 *
 * <p>Nao implementa OutputGuardrail porque precisa do contexto do RAG (que o
 * {@code TutorService} tem). Fail-open. So atua quando ha contexto.
 */
@Component
public class GroundingChecker {

    private static final Logger log = LoggerFactory.getLogger(GroundingChecker.class);

    private static final String SYSTEM = """
            You verify the faithfulness of an English tutor's reply against reference knowledge.
            Given CONTEXT and REPLY, decide if the REPLY's factual claims about grammar/vocabulary
            are supported by the CONTEXT. General encouragement/small talk is always fine.
            Respond ONLY with compact JSON: {"grounded": true|false}. No prose, no markdown.
            """;

    private final GuardrailProperties props;
    private final GuardrailClassifier classifier;

    public GroundingChecker(GuardrailProperties props, GuardrailClassifier classifier) {
        this.props = props;
        this.classifier = classifier;
    }

    public GuardrailResult check(String reply, String contextBlock) {
        if (!props.llmChecksEnabled() || contextBlock == null) {
            return GuardrailResult.ok(); // sem contexto nao ha o que fundamentar
        }
        try {
            JsonNode n = classifier.classify(SYSTEM,
                    "CONTEXT:\n" + contextBlock + "\n\nREPLY:\n" + reply);
            if (!n.path("grounded").asBoolean(true)) {
                return GuardrailResult.block("ungrounded",
                        "Nao tenho base suficiente para afirmar isso com seguranca. Pode reformular a pergunta?");
            }
        } catch (Exception e) {
            log.warn("Checagem de grounding falhou (deixando passar): {}", e.getMessage());
        }
        return GuardrailResult.ok();
    }
}
