package com.diogo.gateway.llm;

import com.diogo.gateway.config.FallbackProperties;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import tools.jackson.databind.JsonNode;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Fallback via Anthropic Messages API (ADR-002), por HTTP direto — consistente com o
 * cliente Gemini. Contrato conferido na skill claude-api:
 * POST /v1/messages, headers x-api-key + anthropic-version: 2023-06-01.
 * Roles: "model" (nossa convenção) → "assistant" (Anthropic); system é campo top-level.
 */
@Component
public class ClaudeClient implements LlmProvider {

    private final FallbackProperties props;
    private final RestClient client;

    public ClaudeClient(FallbackProperties props) {
        this.props = props;
        this.client = RestClient.builder().baseUrl("https://api.anthropic.com").build();
    }

    @Override
    public String name() {
        return "claude";
    }

    @Override
    public LlmResult generate(String model, String systemInstruction, List<LlmTurn> turns) {
        var messages = new ArrayList<Map<String, String>>();
        boolean started = false;
        for (LlmTurn t : turns) {
            String role = "model".equals(t.role()) ? "assistant" : "user";
            // Anthropic exige começar com "user": descarta turns iniciais do assistente.
            if (!started && !"user".equals(role)) {
                continue;
            }
            started = true;
            messages.add(Map.of("role", role, "content", t.text()));
        }

        var body = new HashMap<String, Object>();
        body.put("model", model);
        body.put("max_tokens", props.maxTokens());
        if (systemInstruction != null) {
            body.put("system", systemInstruction);
        }
        body.put("messages", messages);

        JsonNode resp = client.post()
                .uri("/v1/messages")
                .header("x-api-key", props.apiKey())
                .header("anthropic-version", "2023-06-01")
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(JsonNode.class);

        String text = "";
        if (resp != null) {
            for (JsonNode block : resp.path("content")) {
                if ("text".equals(block.path("type").asString(""))) {
                    text = block.path("text").asString("");
                    break;
                }
            }
        }
        int in = resp != null ? resp.path("usage").path("input_tokens").asInt(0) : 0;
        int out = resp != null ? resp.path("usage").path("output_tokens").asInt(0) : 0;
        return new LlmResult("claude", model, text, in, out, in + out);
    }
}
