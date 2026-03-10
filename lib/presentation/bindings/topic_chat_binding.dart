import 'package:get/get.dart';
import '../../data/datasources/gemini_context_datasource.dart';
import '../../data/repositories/context_repository_impl.dart';
import '../../domain/usecases/send_context_message_usecase.dart';
import '../controllers/topic_chat_controller.dart';

class TopicChatBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GeminiContextDatasource>(() => GeminiContextDatasource());
    Get.lazyPut<ContextChatRepository>(
      () => ContextChatRepositoryImpl(dataSource: Get.find()),
    );
    Get.lazyPut<SendContextMessageUseCase>(
      () => SendContextMessageUseCase(Get.find()),
    );
    Get.lazyPut<TopicChatController>(
      () => TopicChatController(sendContextMessageUseCase: Get.find()),
    );
  }
}
