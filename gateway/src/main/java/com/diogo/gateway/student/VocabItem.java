package com.diogo.gateway.student;

/**
 * Item de vocabulário enviado pelo app no sync (espelha o FlashcardModel/SM-2).
 *
 * @param nextReviewEpochMs data de próxima revisão em epoch millis (unívoco, sem timezone)
 */
public record VocabItem(
        String word,
        String translation,
        double easeFactor,
        long nextReviewEpochMs
) {
}
