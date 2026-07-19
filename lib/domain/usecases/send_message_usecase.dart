import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<MessageEntity> call(
    String message, {
    List<MessageEntity> history = const [],
  }) async {
    return await repository.sendMessage(message, history: history);
  }
}
