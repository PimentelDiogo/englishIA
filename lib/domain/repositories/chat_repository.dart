import '../entities/message_entity.dart';

abstract class ChatRepository {
  /// [history] = conversa anterior (para o tutor manter o contexto / multi-turn).
  Future<MessageEntity> sendMessage(
    String message, {
    List<MessageEntity> history = const [],
  });
}
