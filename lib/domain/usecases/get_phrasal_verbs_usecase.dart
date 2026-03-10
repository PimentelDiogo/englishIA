import '../../domain/entities/phrasal_verb_entity.dart';
import '../../data/repositories/context_repository_impl.dart';

class GetPhrasalVerbsUseCase {
  final PhrasalVerbRepository repository;
  GetPhrasalVerbsUseCase(this.repository);

  Future<List<PhrasalVerbEntity>> call({int count = 8}) async {
    return await repository.getPhrasalVerbs(count);
  }
}
