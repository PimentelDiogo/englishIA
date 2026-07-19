package com.diogo.gateway.tutor;

/**
 * Entrada do endpoint /tutor/chat.
 *
 * @param message texto do aluno
 */
public record ChatRequest(String message) {
}
