import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/flashcard_model.dart';
import '../../domain/entities/flashcard_entity.dart';

class StorageService extends GetxService {
  late Isar isar;

  Future<StorageService> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [FlashcardModelSchema],
      directory: dir.path,
    );
    return this;
  }

  /// Recupera todas as revisões pendentes para hoje ou antes de hoje
  Future<List<FlashcardModel>> getDueFlashcards() async {
    final now = DateTime.now();
    return await isar.flashcardModels
        .filter()
        .nextReviewDateLessThan(now)
        .findAll();
  }

  /// Recupera todos os flashcards do sistema (para listagem geral)
  Future<List<FlashcardModel>> getAllFlashcards() async {
    return await isar.flashcardModels.where().findAll();
  }

  /// Salva uma lista de Flashcards recebida da IA
  Future<void> saveNewFlashcards(List<FlashcardEntity> entities) async {
    final models = entities.map((e) => FlashcardModel.fromEntity(e)).toList();
    await isar.writeTxn(() async {
      await isar.flashcardModels.putAll(models);
    });
  }

  /// Atualiza o espaçamento baseado no algoritmo SM-2 (Simplificado)
  /// quality: 0 (Blackout), 1 (Wrong), 2 (Hard), 3 (Good), 4 (Easy)
  Future<void> reviewFlashcard(int id, int quality) async {
    await isar.writeTxn(() async {
      final card = await isar.flashcardModels.get(id);
      if (card == null) return;

      if (quality < 2) {
        // Errou: volta o streak, reseta o intervalo
        card.streak = 0;
        card.interval = 1;
      } else {
        // Acertou
        if (card.streak == 0) {
          card.interval = 1;
        } else if (card.streak == 1) {
          card.interval = 6;
        } else {
          card.interval = (card.interval * card.easeFactor).round();
        }
        card.streak += 1;
      }

      // Atualiza o Ease Factor (quão rápido o cartão avança de espaçamento)
      card.easeFactor = card.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (card.easeFactor < 1.3) card.easeFactor = 1.3; // Mínimo SM-2

      // Define a próxima data de revisão
      card.nextReviewDate = DateTime.now().add(Duration(days: card.interval));

      await isar.flashcardModels.put(card);
    });
  }
}
