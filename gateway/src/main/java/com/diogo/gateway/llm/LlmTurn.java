package com.diogo.gateway.llm;

/**
 * Uma fala da conversa, independente do provedor.
 *
 * @param role "user" (aluno) ou "model" (tutor)
 * @param text conteudo da fala
 */
public record LlmTurn(String role, String text) {
}
