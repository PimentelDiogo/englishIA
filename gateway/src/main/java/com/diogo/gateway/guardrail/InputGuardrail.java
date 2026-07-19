package com.diogo.gateway.guardrail;

/**
 * Guardrail de entrada — roda ANTES do LLM. Cada implementacao e um @Component;
 * a ordem de execucao segue @Order (mais barato/deterministico primeiro).
 */
public interface InputGuardrail {

    GuardrailResult check(String userMessage);
}
