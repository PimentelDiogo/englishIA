import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/tutor_gateway_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final TutorGatewayDatasource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<MessageEntity> sendMessage(
    String message, {
    List<MessageEntity> history = const [],
  }) async {
    try {
      final responseText = await remoteDataSource.sendMessage(
        message,
        history: history,
      );
      return MessageEntity(text: responseText, isUser: false);
    } catch (e) {
      // Surface da mensagem honesta (sem prefixo tecnico "Error:"/"Exception:").
      final honest = e.toString().replaceFirst('Exception: ', '');
      return MessageEntity(text: honest, isUser: false);
    }
  }
}
