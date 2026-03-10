import '../../domain/entities/flashcard_entity.dart';
import '../../data/repositories/context_repository_impl.dart';

class GetFlashcardsUseCase {
  final FlashcardRepository repository;
  GetFlashcardsUseCase(this.repository);

  Future<List<FlashcardEntity>> call({int count = 10}) async {
    return await repository.getFlashcards(count);
  }
}
