import 'package:get/get.dart';
import '../../data/datasources/gemini_context_datasource.dart';
import '../../data/repositories/context_repository_impl.dart';
import '../../domain/usecases/get_phrasal_verbs_usecase.dart';
import '../controllers/phrasal_verb_controller.dart';

class PhrasalVerbBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GeminiPhrasalVerbDatasource>(
      () => GeminiPhrasalVerbDatasource(),
    );
    Get.lazyPut<PhrasalVerbRepository>(
      () => PhrasalVerbRepositoryImpl(dataSource: Get.find()),
    );
    Get.lazyPut<GetPhrasalVerbsUseCase>(
      () => GetPhrasalVerbsUseCase(Get.find()),
    );
    Get.lazyPut<PhrasalVerbController>(
      () => PhrasalVerbController(getPhrasalVerbsUseCase: Get.find()),
    );
  }
}
