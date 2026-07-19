package com.diogo.gateway.guardrail;

import com.diogo.gateway.config.GuardrailProperties;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * Guardrail deterministico #1 (mais barato): rejeita entrada vazia ou longa demais.
 * Zero token gasto.
 */
@Component
@Order(10)
public class LengthInputGuardrail implements InputGuardrail {

    private final GuardrailProperties props;

    public LengthInputGuardrail(GuardrailProperties props) {
        this.props = props;
    }

    @Override
    public GuardrailResult check(String userMessage) {
        if (userMessage == null || userMessage.isBlank()) {
            return GuardrailResult.block("empty_input", "Envie uma mensagem para eu poder ajudar.");
        }
        if (userMessage.length() > props.maxInputLength()) {
            return GuardrailResult.block("input_too_long",
                    "Sua mensagem esta muito longa. Tente encurtar para eu conseguir ajudar melhor.");
        }
        return GuardrailResult.ok();
    }
}
