import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/entities/topic_entity.dart';
import '../../presentation/services/config_service.dart';

class GeminiContextDatasource {
  GenerativeModel? _model;
  ChatSession? _chat;
  String? _currentTopicId;

  void _initSession(TopicEntity topic) {
    if (_currentTopicId == topic.id && _chat != null) return;

    final apiKey = Get.find<ConfigService>().apiKey;
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(topic.systemPrompt),
    );
    _chat = _model!.startChat();
    _currentTopicId = topic.id;
  }

  Future<String> sendMessage(TopicEntity topic, String message) async {
    _initSession(topic);
    final response = await _chat!.sendMessage(Content.text(message));
    return response.text ?? 'No response received.';
  }
}

class GeminiFlashcardDatasource {
  final GenerativeModel _model;

  GeminiFlashcardDatasource()
    : _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: Get.find<ConfigService>().apiKey,
      );

  Future<String> getFlashcardsJson(int count) async {
    final prompt =
        '''Generate $count English vocabulary flashcards for intermediate learners.
Return ONLY a valid JSON array with this structure, no markdown, no explanation:
[
  {
    "word": "resilient",
    "translation": "resiliente",
    "phonetics": "/rɪˈzɪliənt/",
    "exampleSentence": "She is a resilient person who never gives up.",
    "exampleTranslation": "Ela é uma pessoa resiliente que nunca desiste."
  }
]''';

    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? '[]';
  }
}

class GeminiPhrasalVerbDatasource {
  final GenerativeModel _model;

  GeminiPhrasalVerbDatasource()
    : _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: Get.find<ConfigService>().apiKey,
      );

  Future<String> getPhrasalVerbsJson(int count) async {
    final prompt =
        '''Generate $count common English phrasal verbs that are useful for everyday conversation.
Return ONLY a valid JSON array with this exact structure, no markdown, no explanation:
[
  {
    "verb": "give up",
    "meaning": "To stop trying or doing something",
    "examples": [
      "He gave up smoking last year.",
      "Don't give up! You can do it!"
    ],
    "exerciseSentence": "She decided to _______ piano lessons because she was too busy.",
    "exerciseAnswer": "give up"
  }
]''';

    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? '[]';
  }
}
