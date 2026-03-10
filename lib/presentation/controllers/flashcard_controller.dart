import 'package:get/get.dart';
import '../../domain/entities/flashcard_entity.dart';
import '../../domain/usecases/get_flashcards_usecase.dart';

class FlashcardController extends GetxController {
  final GetFlashcardsUseCase getFlashcardsUseCase;
  FlashcardController({required this.getFlashcardsUseCase});

  final flashcards = <FlashcardEntity>[].obs;
  final repeatList = <FlashcardEntity>[].obs;
  final currentIndex = 0.obs;
  final isFlipped = false.obs;
  final isLoading = true.obs;
  final isShowingRepeatSession = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadFlashcards();
  }

  Future<void> loadFlashcards() async {
    isLoading.value = true;
    final cards = await getFlashcardsUseCase(count: 10);
    flashcards.assignAll(cards);
    isLoading.value = false;
  }

  List<FlashcardEntity> get activeList =>
      isShowingRepeatSession.value ? repeatList : flashcards;

  void flipCard() => isFlipped.value = !isFlipped.value;

  void gotIt() {
    isFlipped.value = false;
    if (currentIndex.value < activeList.length - 1) {
      currentIndex.value++;
    } else {
      _onSessionEnd();
    }
  }

  void repeat() {
    if (!isShowingRepeatSession.value) {
      repeatList.add(activeList[currentIndex.value]);
    }
    isFlipped.value = false;
    if (currentIndex.value < activeList.length - 1) {
      currentIndex.value++;
    } else {
      _onSessionEnd();
    }
  }

  void startRepeatSession() {
    isShowingRepeatSession.value = true;
    currentIndex.value = 0;
    isFlipped.value = false;
  }

  void _onSessionEnd() {
    // Session finished - if there are repeat cards, show option
  }

  void restartSession() {
    isShowingRepeatSession.value = false;
    repeatList.clear();
    currentIndex.value = 0;
    isFlipped.value = false;
  }
}
