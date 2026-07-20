package com.diogo.gateway.student;

/**
 * Um item de vocabulário do aluno (espelha o FlashcardModel/SM-2 do Isar).
 *
 * @param word       a palavra/expressão
 * @param translation tradução
 * @param easeFactor  fator SM-2 (menor = o aluno erra mais → "fraco")
 */
public record StudentWord(String word, String translation, double easeFactor) {
}
