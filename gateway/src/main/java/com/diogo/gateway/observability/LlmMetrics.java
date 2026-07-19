package com.diogo.gateway.observability;

import com.diogo.gateway.config.GeminiProperties;
import com.diogo.gateway.llm.LlmResult;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tags;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

/**
 * Observabilidade de LLM — o entregavel central da Fase 1: medir tokens, custo e
 * latencia desde o dia 1 (SLO de custo do PRD-ai-tutor).
 *
 * <p>Registra em duas frentes:
 * <ul>
 *   <li>Micrometer (Actuator /metrics): contadores de tokens/custo e timer de latencia.</li>
 *   <li>Log estruturado por request (facil de grep / mandar pra um coletor depois).</li>
 * </ul>
 */
@Component
public class LlmMetrics {

    private static final Logger log = LoggerFactory.getLogger(LlmMetrics.class);

    private final MeterRegistry registry;
    private final GeminiProperties props;

    public LlmMetrics(MeterRegistry registry, GeminiProperties props) {
        this.registry = registry;
        this.props = props;
    }

    /**
     * @param task      rotulo da tarefa (ex.: "chat") — vira dimensao das metricas
     * @param result    resultado normalizado do LLM
     * @param latencyMs latencia da chamada em milissegundos
     * @return custo estimado da chamada em USD
     */
    public double record(String task, LlmResult result, long latencyMs) {
        double cost = estimateCost(result);
        Tags tags = Tags.of("provider", result.provider(), "model", result.model(), "task", task);

        registry.counter("llm.tokens.input", tags).increment(result.promptTokens());
        registry.counter("llm.tokens.output", tags).increment(result.outputTokens());
        registry.counter("llm.cost.usd", tags).increment(cost);
        registry.timer("llm.latency", tags).record(latencyMs, TimeUnit.MILLISECONDS);

        log.info("llm_call task={} provider={} model={} tokens_in={} tokens_out={} tokens_total={} custo_estimado_usd={} latencia_ms={}",
                task, result.provider(), result.model(),
                result.promptTokens(), result.outputTokens(), result.totalTokens(),
                String.format("%.6f", cost), latencyMs);

        return cost;
    }

    /** Registra um bloqueio de guardrail (entrada ou saida) por motivo. */
    public void recordGuardrailBlock(String stage, String code) {
        registry.counter("llm.guardrail.blocked", Tags.of("stage", stage, "code", code)).increment();
        log.info("guardrail_block stage={} code={}", stage, code);
    }

    /** Cache semântico: HIT (respondeu do cache, 0 token do modelo forte) ou MISS. */
    public void recordCache(boolean hit) {
        registry.counter("llm.cache", Tags.of("result", hit ? "hit" : "miss")).increment();
        if (hit) {
            log.info("semantic_cache result=hit (0 token do modelo forte)");
        }
    }

    /** Roteamento: qual modelo foi escolhido para a tarefa. */
    public void recordRoute(String model) {
        registry.counter("llm.route", Tags.of("model", model)).increment();
    }

    private double estimateCost(LlmResult r) {
        return r.promptTokens() / 1_000_000.0 * props.inputPricePerMillion()
                + r.outputTokens() / 1_000_000.0 * props.outputPricePerMillion();
    }
}
