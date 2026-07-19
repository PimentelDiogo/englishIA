package com.diogo.gateway.guardrail;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Orquestra os guardrails em ordem (fail-fast): o primeiro que bloquear encerra.
 * O Spring injeta as listas ja ordenadas por @Order.
 */
@Component
public class GuardrailChain {

    private static final Logger log = LoggerFactory.getLogger(GuardrailChain.class);

    private final List<InputGuardrail> inputGuardrails;
    private final List<OutputGuardrail> outputGuardrails;

    public GuardrailChain(List<InputGuardrail> inputGuardrails, List<OutputGuardrail> outputGuardrails) {
        this.inputGuardrails = inputGuardrails;
        this.outputGuardrails = outputGuardrails;
    }

    public GuardrailResult checkInput(String userMessage) {
        for (InputGuardrail g : inputGuardrails) {
            GuardrailResult r = g.check(userMessage);
            if (!r.allowed()) {
                log.info("guardrail_block stage=input code={} by={}", r.code(),
                        g.getClass().getSimpleName());
                return r;
            }
        }
        return GuardrailResult.ok();
    }

    public GuardrailResult checkOutput(String userMessage, String reply) {
        for (OutputGuardrail g : outputGuardrails) {
            GuardrailResult r = g.check(userMessage, reply);
            if (!r.allowed()) {
                log.info("guardrail_block stage=output code={} by={}", r.code(),
                        g.getClass().getSimpleName());
                return r;
            }
        }
        return GuardrailResult.ok();
    }
}
