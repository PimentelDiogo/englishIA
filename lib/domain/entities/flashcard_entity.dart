class FlashcardEntity {
  final String word;
  final String translation;
  final String phonetics;
  final String exampleSentence;
  final String exampleTranslation;
  final DateTime? nextReviewDate;

  const FlashcardEntity({
    required this.word,
    required this.translation,
    required this.phonetics,
    required this.exampleSentence,
    required this.exampleTranslation,
    this.nextReviewDate,
  });

  factory FlashcardEntity.fromJson(Map<String, dynamic> json) {
    return FlashcardEntity(
      word: json['word'] ?? '',
      translation: json['translation'] ?? '',
      phonetics: json['phonetics'] ?? '',
      exampleSentence: json['exampleSentence'] ?? '',
      exampleTranslation: json['exampleTranslation'] ?? '',
    );
  }
}
