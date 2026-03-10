import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/gemini_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final GeminiDatasource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<MessageEntity> sendMessage(String message) async {
    try {
      final responseText = await remoteDataSource.sendMessage(message);
      return MessageEntity(text: responseText, isUser: false);
    } catch (e) {
      return MessageEntity(text: 'Error: ${e.toString()}', isUser: false);
    }
  }
}
