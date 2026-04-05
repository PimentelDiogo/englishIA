import 'package:get/get.dart';
import '../../domain/entities/flashcard_entity.dart';
import '../../domain/usecases/get_flashcards_usecase.dart';
import '../services/storage_service.dart';

class FlashcardController extends GetxController {
  final GetFlashcardsUseCase getFlashcardsUseCase;
  FlashcardController({required this.getFlashcardsUseCase});

  final flashcards = <FlashcardEntity>[].obs;
  final repeatList = <FlashcardEntity>[].obs;
  final currentIndex = 0.obs;
  final isFlipped = false.obs;
  final isLoading = true.obs;
  final isShowingRepeatSession = false.obs;
  
  late final StorageService _storageService;

  @override
  void onInit() {
    super.onInit();
    _storageService = Get.find<StorageService>();
    loadFlashcards();
  }

  Future<void> loadFlashcards() async {
    isLoading.value = true;
    
    // 1. Check for due flashcards in local database
    final dueModels = await _storageService.getDueFlashcards();
    if (dueModels.isNotEmpty) {
      flashcards.assignAll(dueModels.map((m) => m.toEntity()));
    } else {
      // 2. No due cards today. Ask AI for 10 new cards
      final newCards = await getFlashcardsUseCase(count: 10);
      
      // 3. Save new cards to local database
      await _storageService.saveNewFlashcards(newCards);
      
      // 4. Retrieve them back (so they have valid Isar IDs)
      final generatedModels = await _storageService.getDueFlashcards();
      flashcards.assignAll(generatedModels.map((m) => m.toEntity()));
    }
    
    isLoading.value = false;
  }

  List<FlashcardEntity> get activeList =>
      isShowingRepeatSession.value ? repeatList : flashcards;

  void flipCard() => isFlipped.value = !isFlipped.value;

  Future<void> gotIt() async {
    isFlipped.value = false;
    
    // Evaluate via SM-2: Quality 4 (Easy)
    final card = activeList[currentIndex.value];
    if (card.id != null) {
      await _storageService.reviewFlashcard(card.id!, 4);
    }
    
    if (currentIndex.value < activeList.length - 1) {
      currentIndex.value++;
    } else {
      _onSessionEnd();
    }
  }

  Future<void> repeat() async {
    final card = activeList[currentIndex.value];
    
    // Evaluate via SM-2: Quality 1 (Wrong / Hard)
    if (card.id != null) {
      await _storageService.reviewFlashcard(card.id!, 1);
    }
    
    if (!isShowingRepeatSession.value) {
      repeatList.add(card);
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
