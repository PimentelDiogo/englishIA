package com.diogo.gateway.web;

import com.diogo.gateway.llm.LlmException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Traduz excecoes internas em respostas honestas e limpas para o cliente.
 * Substitui o 500 cru do Spring por um contrato de erro estavel (ErrorResponse).
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    /** Provedor de LLM indisponivel/erro → 502 com mensagem honesta. */
    @ExceptionHandler(LlmException.class)
    public ResponseEntity<ErrorResponse> handleLlm(LlmException ex) {
        return ResponseEntity
                .status(HttpStatus.BAD_GATEWAY)
                .body(new ErrorResponse("tutor_unavailable", ex.getMessage()));
    }

    /** Qualquer outra falha inesperada → 500, mas ainda honesta e sem vazar detalhe. */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex) {
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("internal_error",
                        "Algo deu errado do nosso lado. Tente novamente."));
    }
}
