package com.diogo.gateway.llm;

import com.diogo.gateway.config.GeminiProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

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
     * @param systemInstruction persona do tutor (pode ser null)
     * @param userText          mensagem do aluno
     */
    public LlmResult generate(String systemInstruction, String userText) {
        var content = new GeminiDtos.Content(List.of(new GeminiDtos.Part(userText)));
        var system = systemInstruction == null ? null
                : new GeminiDtos.Content(List.of(new GeminiDtos.Part(systemInstruction)));
        var body = new GeminiDtos.Request(List.of(content), system);

        try {
            GeminiDtos.Response resp = restClient.post()
                    .uri("/v1beta/models/{model}:generateContent?key={key}", props.model(), props.apiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(GeminiDtos.Response.class);

            return toResult(resp);
        } catch (RestClientException e) {
            // Log tecnico completo fica no servidor; usuario recebe mensagem honesta e limpa.
            log.warn("Falha ao chamar o provedor Gemini: {}", e.getMessage());
            throw new LlmException(
                    "O tutor esta indisponivel no momento. Tente novamente em instantes.", e);
        }
    }

    private LlmResult toResult(GeminiDtos.Response resp) {
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

        return new LlmResult("gemini", props.model(), text, in, out, total);
    }
}
