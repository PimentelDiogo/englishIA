package com.diogo.gateway.web;

/**
 * Corpo de erro padronizado do gateway. Mensagem sempre honesta e apresentavel —
 * nunca stacktrace ou detalhe do provedor.
 *
 * @param error   codigo estavel para o cliente tratar (ex.: "tutor_unavailable")
 * @param message texto amigavel para mostrar ao usuario
 */
public record ErrorResponse(String error, String message) {
}
