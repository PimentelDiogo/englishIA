import 'package:get/get.dart';
import '../../domain/entities/phrasal_verb_entity.dart';
import '../../domain/usecases/get_phrasal_verbs_usecase.dart';

class PhrasalVerbController extends GetxController {
  final GetPhrasalVerbsUseCase getPhrasalVerbsUseCase;
  PhrasalVerbController({required this.getPhrasalVerbsUseCase});

  final phrasalVerbs = <PhrasalVerbEntity>[].obs;
  final isLoading = true.obs;
  final selectedIndex = (-1).obs;
  final exerciseAnswer = ''.obs;
  final exerciseResult = Rx<bool?>(null);

  @override
  void onInit() {
    super.onInit();
    loadPhrasalVerbs();
  }

  Future<void> loadPhrasalVerbs() async {
    isLoading.value = true;
    final verbs = await getPhrasalVerbsUseCase(count: 8);
    phrasalVerbs.assignAll(verbs);
    isLoading.value = false;
  }

  void selectVerb(int index) {
    selectedIndex.value = selectedIndex.value == index ? -1 : index;
    exerciseAnswer.value = '';
    exerciseResult.value = null;
  }

  void checkAnswer(String answer) {
    final selected = phrasalVerbs[selectedIndex.value];
    exerciseResult.value =
        answer.toLowerCase().trim() ==
        selected.exerciseAnswer.toLowerCase().trim();
  }
}
