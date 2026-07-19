package com.diogo.gateway.guardrail;

import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.regex.Pattern;

/**
 * Guardrail deterministico #2: pega padroes OBVIOS de prompt injection / jailbreak
 * por regex (barato, zero token). Nao substitui o Lakera (que pega casos nuancados) —
 * e a primeira linha rapida de defesa.
 */
@Component
@Order(20)
public class PromptInjectionInputGuardrail implements InputGuardrail {

    // Padroes classicos em EN e PT. Case-insensitive.
    private static final List<Pattern> PATTERNS = List.of(
            Pattern.compile("ignore (all |the )?(previous|prior|above) (instructions|prompts?)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("disregard (all |the )?(previous|prior|above)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("ignore(m|r)? (as |todas as )?(instruções|regras) (anteriores|acima)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("you are now|from now on,? you are|act as (?:a )?(?:DAN|jailbreak)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("system prompt|reveal your (instructions|system|prompt)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("developer mode|do anything now", Pattern.CASE_INSENSITIVE)
    );

    @Override
    public GuardrailResult check(String userMessage) {
        for (Pattern p : PATTERNS) {
            if (p.matcher(userMessage).find()) {
                return GuardrailResult.block("prompt_injection",
                        "Nao posso seguir esse tipo de instrucao. Vamos voltar a praticar ingles?");
            }
        }
        return GuardrailResult.ok();
    }
}
