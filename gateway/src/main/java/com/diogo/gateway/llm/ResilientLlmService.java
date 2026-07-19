package com.diogo.gateway.llm;

import com.diogo.gateway.config.FallbackProperties;
import com.diogo.gateway.observability.LlmMetrics;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.List;
import java.util.function.Supplier;

/**
 * Resiliência do LLM (ADR-002): tenta o Gemini com retry + circuit breaker; se falhar
 * (ou o circuito abrir), cai para o Claude. Se o fallback estiver desligado ou também
 * falhar, devolve erro honesto ({@link LlmException}).
 */
@Service
public class ResilientLlmService {

    private static final Logger log = LoggerFactory.getLogger(ResilientLlmService.class);
    private static final String HONEST =
            "O tutor esta indisponivel no momento. Tente novamente em instantes.";

    private final LlmProvider primary;   // Gemini
    private final LlmProvider fallback;  // Claude
    private final FallbackProperties props;
    private final LlmMetrics metrics;
    private final CircuitBreaker circuitBreaker;
    private final Retry retry;

    public ResilientLlmService(@Qualifier("geminiClient") LlmProvider primary,
                               @Qualifier("claudeClient") LlmProvider fallback,
                               FallbackProperties props, LlmMetrics metrics) {
        this.primary = primary;
        this.fallback = fallback;
        this.props = props;
        this.metrics = metrics;
        this.circuitBreaker = CircuitBreaker.of("llm", CircuitBreakerConfig.custom()
                .failureRateThreshold(50)
                .slidingWindowSize(10)
                .waitDurationInOpenState(Duration.ofSeconds(20))
                .build());
        this.retry = Retry.of("llm", RetryConfig.custom()
                .maxAttempts(2)
                .waitDuration(Duration.ofMillis(300))
                .build());
    }

    public LlmResult generate(String model, String system, List<LlmTurn> turns) {
        Supplier<LlmResult> primaryCall = () -> primary.generate(model, system, turns);
        Supplier<LlmResult> resilient = Retry.decorateSupplier(retry,
                CircuitBreaker.decorateSupplier(circuitBreaker, primaryCall));
        try {
            return resilient.get();
        } catch (Exception primaryError) {
            if (!props.enabled()) {
                throw new LlmException(HONEST, primaryError);
            }
            log.warn("Primário ({}) falhou; caindo para o fallback ({}): {}",
                    primary.name(), fallback.name(), primaryError.getMessage());
            metrics.recordFallback(fallback.name());
            try {
                return fallback.generate(props.model(), system, turns);
            } catch (Exception fallbackError) {
                throw new LlmException(HONEST, fallbackError);
            }
        }
    }
}
