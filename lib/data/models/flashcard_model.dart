import 'package:isar/isar.dart';
import '../../domain/entities/flashcard_entity.dart';

part 'flashcard_model.g.dart';

@collection
class FlashcardModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String word;
  
  late String translation;
  late String phonetics;
  late String exampleSentence;
  late String exampleTranslation;

  // Campos para o Algoritmo de Repetição Espaçada (SRS - SM2)
  DateTime nextReviewDate = DateTime.now();
  int interval = 0; 
  double easeFactor = 2.5;
  int streak = 0;

  // Constructor vazio exigido pelo Isar
  FlashcardModel();

  factory FlashcardModel.fromEntity(FlashcardEntity entity) {
    return FlashcardModel()
      ..word = entity.word
      ..translation = entity.translation
      ..phonetics = entity.phonetics
      ..exampleSentence = entity.exampleSentence
      ..exampleTranslation = entity.exampleTranslation;
  }

  FlashcardEntity toEntity() {
    return FlashcardEntity(
      word: word,
      translation: translation,
      phonetics: phonetics,
      exampleSentence: exampleSentence,
      exampleTranslation: exampleTranslation,
      nextReviewDate: nextReviewDate,
    );
  }
}
