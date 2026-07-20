package com.diogo.gateway.rag;

import com.diogo.gateway.config.GeminiProperties;
import com.diogo.gateway.config.RagProperties;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

/**
 * Gera embeddings via Gemini (mesmo provedor/chave do tutor — sem SaaS novo).
 * Endpoint: POST /v1beta/models/{model}:embedContent
 *
 * <p>Confirmado contra a API viva: modelo `gemini-embedding-001` (o `text-embedding-004` foi
 * descontinuado). Ele sai em 3072 dims por padrão → pedimos `outputDimensionality` = 768 para
 * bater com a coluna `vector(768)`.
 */
@Component
public class GeminiEmbeddingClient {

    private final RestClient client;
    private final GeminiProperties gemini;
    private final RagProperties rag;

    public GeminiEmbeddingClient(GeminiProperties gemini, RagProperties rag) {
        this.gemini = gemini;
        this.rag = rag;
        this.client = RestClient.builder().baseUrl(gemini.baseUrl()).build();
    }

    /** Embedding do texto como float[] (dimensao = rag.embeddingDimensions). */
    public float[] embed(String text) {
        EmbedResponse resp = client.post()
                .uri("/v1beta/models/{model}:embedContent?key={key}", rag.embeddingModel(), gemini.apiKey())
                .contentType(MediaType.APPLICATION_JSON)
                .body(Map.of(
                        "content", Map.of("parts", List.of(Map.of("text", text))),
                        "outputDimensionality", rag.embeddingDimensions()))
                .retrieve()
                .body(EmbedResponse.class);

        List<Double> values = resp != null && resp.embedding() != null ? resp.embedding().values() : null;
        if (values == null || values.isEmpty()) {
            throw new IllegalStateException("Embedding vazio retornado pelo provedor.");
        }
        float[] out = new float[values.size()];
        for (int i = 0; i < values.size(); i++) {
            out[i] = values.get(i).floatValue();
        }
        return out;
    }

    // DTOs do embedContent
    record EmbedResponse(Embedding embedding) {
    }

    record Embedding(List<Double> values) {
    }
}
