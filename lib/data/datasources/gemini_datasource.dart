import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../presentation/services/config_service.dart';

class GeminiDatasource {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiDatasource() {
    final apiKey = Get.find<ConfigService>().apiKey;
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'You are an English teacher. The user is practicing English. Correct their mistakes, explain them briefly, and continue the conversation in a friendly manner.',
      ),
    );
    _chat = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    final apiKey = Get.find<ConfigService>().apiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception(
        'Gemini API Key is not configured. Please go to Settings to add your key.',
      );
    }
    final response = await _chat.sendMessage(Content.text(message));
    return response.text ?? 'No response from the assistant.';
  }
}
