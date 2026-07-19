package com.diogo.gateway.rag;

/**
 * Um trecho da base de conhecimento recuperado do vector store.
 *
 * @param content  texto (regra gramatical, phrasal verb, etc.)
 * @param category origem ("grammar", "phrasal_verb", ...)
 * @param distance distancia de cosseno para a query (menor = mais relevante)
 */
public record KnowledgeChunk(String content, String category, double distance) {
}
