import 'package:get/get.dart';
import '../../data/datasources/gemini_context_datasource.dart';
import '../../data/repositories/context_repository_impl.dart';
import '../../domain/usecases/get_flashcards_usecase.dart';
import '../controllers/flashcard_controller.dart';

class FlashcardBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GeminiFlashcardDatasource>(() => GeminiFlashcardDatasource());
    Get.lazyPut<FlashcardRepository>(
      () => FlashcardRepositoryImpl(dataSource: Get.find()),
    );
    Get.lazyPut<GetFlashcardsUseCase>(() => GetFlashcardsUseCase(Get.find()));
    Get.lazyPut<FlashcardController>(
      () => FlashcardController(getFlashcardsUseCase: Get.find()),
    );
  }
}
