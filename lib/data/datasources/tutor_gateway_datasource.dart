import 'dart:convert';

import 'package:get/get.dart' hide Response;
import 'package:http/http.dart' as http;

import '../../domain/entities/message_entity.dart';
import '../../presentation/services/config_service.dart';

/// Datasource do chat livre via AI Gateway (ADR-001), no lugar da chamada direta
/// ao Gemini. A API key nao vive mais no cliente — quem fala com o LLM e o gateway.
///
/// Multi-turn: o gateway e stateless, entao o cliente envia o [history] da conversa
/// em cada request. Cada turn vira {role: "user"|"model", text}.
class TutorGatewayDatasource {
  final http.Client _client;

  TutorGatewayDatasource({http.Client? client})
      : _client = client ?? http.Client();

  Future<String> sendMessage(
    String message, {
    List<MessageEntity> history = const [],
  }) async {
    final baseUrl = Get.find<ConfigService>().gatewayUrl;
    final uri = Uri.parse('$baseUrl/tutor/chat');

    final historyJson = history
        .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
        .toList();

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message, 'history': historyJson}),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      // Falha de rede/timeout: mensagem honesta, sem detalhe tecnico.
      throw Exception(
        'Nao consegui falar com o tutor. Verifique sua conexao e se o gateway esta no ar.',
      );
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['reply'] as String? ?? 'No response from the assistant.';
    }

    // Erro do gateway: usa a mensagem honesta que o proprio backend devolve.
    throw Exception(_honestError(response.body));
  }

  String _honestError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    } catch (_) {
      // corpo nao-JSON: cai no fallback abaixo
    }
    return 'O tutor esta indisponivel no momento. Tente novamente em instantes.';
  }
}
