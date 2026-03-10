import '../entities/message_entity.dart';

abstract class ChatRepository {
  Future<MessageEntity> sendMessage(String message);
}
