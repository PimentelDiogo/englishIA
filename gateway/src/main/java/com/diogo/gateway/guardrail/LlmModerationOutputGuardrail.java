package com.diogo.gateway.guardrail;

import com.diogo.gateway.config.GuardrailProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import tools.jackson.databind.JsonNode;

/**
 * Guardrail de SAIDA: moderacao da resposta do tutor via flash-lite (ADR-005).
 * O publico pode incluir menores (matriz de risco do PRD). Fail-open em erro.
 */
@Component
public class LlmModerationOutputGuardrail implements OutputGuardrail {

    private static final Logger log = LoggerFactory.getLogger(LlmModerationOutputGuardrail.class);

    private static final String SYSTEM = """
            You are a content-safety classifier for an English tutor whose users may be minors.
            Given the assistant's reply, decide if it contains unsafe content
            (sexual, violent, hateful, self-harm, or otherwise inappropriate for minors).
            Respond ONLY with compact JSON: {"unsafe": true|false}. No prose, no markdown.
            """;

    private final GuardrailProperties props;
    private final GuardrailClassifier classifier;

    public LlmModerationOutputGuardrail(GuardrailProperties props, GuardrailClassifier classifier) {
        this.props = props;
        this.classifier = classifier;
    }

    @Override
    public GuardrailResult check(String userMessage, String reply) {
        if (!props.llmChecksEnabled()) {
            return GuardrailResult.ok();
        }
        try {
            JsonNode n = classifier.classify(SYSTEM, reply);
            if (n.path("unsafe").asBoolean(false)) {
                return GuardrailResult.block("unsafe_output",
                        "Desculpe, nao consigo responder isso agora. Podemos tentar de outro jeito?");
            }
        } catch (Exception e) {
            log.warn("Moderacao de saida falhou (deixando passar): {}", e.getMessage());
        }
        return GuardrailResult.ok();
    }
}
