package com.diogo.gateway.tutor;

import java.util.List;

/**
 * Entrada do endpoint /tutor/chat.
 *
 * @param message mensagem atual do aluno
 * @param history conversa anterior (pode ser null/vazia). Cada turn: role "user"|"model".
 *                O gateway e stateless — quem mantem o historico e o cliente.
 * @param userId  id do aluno (opcional) — habilita a personalização por histórico (ADR-006).
 */
public record ChatRequest(String message, List<Turn> history, String userId) {

    public record Turn(String role, String text) {
    }
}
