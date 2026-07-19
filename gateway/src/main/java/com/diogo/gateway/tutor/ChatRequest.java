package com.diogo.gateway.tutor;

import java.util.List;

/**
 * Entrada do endpoint /tutor/chat.
 *
 * @param message mensagem atual do aluno
 * @param history conversa anterior (pode ser null/vazia). Cada turn: role "user"|"model".
 *                O gateway e stateless — quem mantem o historico e o cliente.
 */
public record ChatRequest(String message, List<Turn> history) {

    public record Turn(String role, String text) {
    }
}
