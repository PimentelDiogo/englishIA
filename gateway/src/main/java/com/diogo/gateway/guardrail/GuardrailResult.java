package com.diogo.gateway.guardrail;

/**
 * Veredito de um guardrail.
 *
 * @param allowed true = segue; false = bloqueia
 * @param code    codigo estavel do motivo (ex.: "off_scope", "prompt_injection", "jailbreak",
 *                "unsafe_output") — vira dimensao de metrica
 * @param message mensagem honesta para o usuario quando bloqueado (null se allowed)
 */
public record GuardrailResult(boolean allowed, String code, String message) {

    private static final GuardrailResult OK = new GuardrailResult(true, null, null);

    public static GuardrailResult ok() {
        return OK;
    }

    public static GuardrailResult block(String code, String message) {
        return new GuardrailResult(false, code, message);
    }
}
