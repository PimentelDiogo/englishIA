import '../../domain/entities/message_entity.dart';
import '../../domain/entities/topic_entity.dart';
import '../../data/repositories/context_repository_impl.dart';

class SendContextMessageUseCase {
  final ContextChatRepository repository;
  SendContextMessageUseCase(this.repository);

  Future<MessageEntity> call(TopicEntity topic, String message) async {
    return await repository.sendContextMessage(topic, message);
  }
}
