package com.diogo.gateway.llm;

import com.diogo.gateway.config.GeminiProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.ArrayList;
import java.util.List;

/**
 * Cliente do provedor primario (Gemini) via RestClient sincrono.
 * Isola o formato do Gemini: o resto do gateway so ve {@link LlmResult}.
 */
@Component
public class GeminiClient {

    private static final Logger log = LoggerFactory.getLogger(GeminiClient.class);

    private final RestClient restClient;
    private final GeminiProperties props;

    public GeminiClient(GeminiProperties props) {
        this.props = props;
        this.restClient = RestClient.builder().baseUrl(props.baseUrl()).build();
    }

    /**
     * Gera a resposta do tutor a partir da conversa completa (multi-turn).
     *
     * @param systemInstruction persona do tutor (pode ser null)
     * @param turns             conversa em ordem; a ultima fala deve ser do aluno ("user")
     */
    public LlmResult generate(String systemInstruction, List<LlmTurn> turns) {
        return generate(props.model(), systemInstruction, turns);
    }

    /**
     * Variante com modelo explicito — usada por tarefas auxiliares baratas
     * (ex.: classificador de guardrail), alinhado ao roteamento de custo do ADR-004.
     */
    public LlmResult generate(String model, String systemInstruction, List<LlmTurn> turns) {
        var contents = new ArrayList<GeminiDtos.Content>();
        boolean started = false;
        for (LlmTurn t : turns) {
            // Gemini exige que `contents` comece com role "user": descarta turns iniciais
            // que sejam do modelo (ex.: mensagem de boas-vindas do tutor).
            if (!started && !"user".equals(t.role())) {
                continue;
            }
            started = true;
            contents.add(new GeminiDtos.Content(t.role(), List.of(new GeminiDtos.Part(t.text()))));
        }
        var system = systemInstruction == null ? null
                : new GeminiDtos.Content(null, List.of(new GeminiDtos.Part(systemInstruction)));
        var body = new GeminiDtos.Request(contents, system);

        try {
            GeminiDtos.Response resp = restClient.post()
                    .uri("/v1beta/models/{model}:generateContent?key={key}", model, props.apiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(GeminiDtos.Response.class);

            return toResult(model, resp);
        } catch (RestClientException e) {
            // Log tecnico completo fica no servidor; usuario recebe mensagem honesta e limpa.
            log.warn("Falha ao chamar o provedor Gemini: {}", e.getMessage());
            throw new LlmException(
                    "O tutor esta indisponivel no momento. Tente novamente em instantes.", e);
        }
    }

    private LlmResult toResult(String model, GeminiDtos.Response resp) {
        String text = "";
        if (resp != null && resp.candidates() != null && !resp.candidates().isEmpty()) {
            var parts = resp.candidates().get(0).content().parts();
            if (parts != null && !parts.isEmpty()) {
                text = parts.get(0).text();
            }
        }
        var usage = resp == null ? null : resp.usageMetadata();
        int in = usage != null && usage.promptTokenCount() != null ? usage.promptTokenCount() : 0;
        int out = usage != null && usage.candidatesTokenCount() != null ? usage.candidatesTokenCount() : 0;
        int total = usage != null && usage.totalTokenCount() != null ? usage.totalTokenCount() : in + out;

        return new LlmResult("gemini", model, text, in, out, total);
    }
}
