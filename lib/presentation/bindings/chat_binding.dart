import 'package:get/get.dart';
import '../../data/datasources/gemini_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../controllers/chat_controller.dart';

class ChatBinding implements Bindings {
  @override
  void dependencies() {
    // Data sources
    Get.lazyPut<GeminiDatasource>(() => GeminiDatasource());

    // Repositories
    Get.lazyPut<ChatRepository>(
      () => ChatRepositoryImpl(remoteDataSource: Get.find<GeminiDatasource>()),
    );

    // Use cases
    Get.lazyPut<SendMessageUseCase>(
      () => SendMessageUseCase(Get.find<ChatRepository>()),
    );

    // Controllers
    Get.lazyPut<ChatController>(
      () => ChatController(sendMessageUseCase: Get.find<SendMessageUseCase>()),
    );
  }
}
