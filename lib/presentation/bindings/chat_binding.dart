import 'package:get/get.dart';
import '../../data/datasources/tutor_gateway_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../controllers/chat_controller.dart';

class ChatBinding implements Bindings {
  @override
  void dependencies() {
    // Data sources — chat livre agora passa pelo AI Gateway (ADR-001)
    Get.lazyPut<TutorGatewayDatasource>(() => TutorGatewayDatasource());

    // Repositories
    Get.lazyPut<ChatRepository>(
      () => ChatRepositoryImpl(
        remoteDataSource: Get.find<TutorGatewayDatasource>(),
      ),
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
