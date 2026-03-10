import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/constants.dart';

class GeminiDatasource {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiDatasource() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Constants.geminiApiKey,
      systemInstruction: Content.system(
        'You are an English teacher. The user is practicing English. Correct their mistakes, explain them briefly, and continue the conversation in a friendly manner.',
      ),
    );
    _chat = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    if (Constants.geminiApiKey.isEmpty ||
        Constants.geminiApiKey == 'YOUR_API_KEY_HERE') {
      throw Exception(
        'Gemini API Key is not configured. Please add it to lib/core/constants/constants.dart',
      );
    }
    final response = await _chat.sendMessage(Content.text(message));
    return response.text ?? 'No response from the assistant.';
  }
}
