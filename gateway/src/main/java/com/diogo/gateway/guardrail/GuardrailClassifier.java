package com.diogo.gateway.guardrail;

import com.diogo.gateway.config.GeminiProperties;
import com.diogo.gateway.llm.GeminiClient;
import com.diogo.gateway.llm.LlmResult;
import com.diogo.gateway.llm.LlmTurn;
import org.springframework.stereotype.Component;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.util.List;

/**
 * Helper compartilhado: roda um classificador com o modelo BARATO (flash-lite, ADR-004)
 * e devolve o JSON parseado. Sem SaaS externo — reusa o Gemini que o app ja usa.
 * Lanca em caso de falha; cada guardrail decide o fail-open.
 */
@Component
class GuardrailClassifier {

    private final GeminiClient gemini;
    private final GeminiProperties props;
    private final ObjectMapper mapper;

    GuardrailClassifier(GeminiClient gemini, GeminiProperties props, ObjectMapper mapper) {
        this.gemini = gemini;
        this.props = props;
        this.mapper = mapper;
    }

    JsonNode classify(String system, String content) {
        LlmResult r = gemini.generate(props.classifierModel(), system,
                List.of(new LlmTurn("user", content)));
        String json = r.text().replace("```json", "").replace("```", "").trim();
        return mapper.readTree(json);
    }
}
