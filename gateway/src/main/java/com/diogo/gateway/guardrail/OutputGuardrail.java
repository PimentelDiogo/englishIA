package com.diogo.gateway.guardrail;

/**
 * Guardrail de saida — roda DEPOIS do LLM, antes de devolver ao usuario.
 */
public interface OutputGuardrail {

    GuardrailResult check(String userMessage, String reply);
}
