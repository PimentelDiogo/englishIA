class Constants {
  // Use --dart-define=GEMINI_API_KEY=your_key or env.json
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'apiKeyAQUI',
  );

  // URL do AI Gateway (ADR-001). O chat livre passa por aqui em vez de chamar o
  // Gemini direto. Override via --dart-define=GATEWAY_URL=... ou Settings.
  // Atencao ao rodar em emulador Android: use http://10.0.2.2:8080 (nao localhost).
  static const String gatewayUrl = String.fromEnvironment(
    'GATEWAY_URL',
    defaultValue: 'http://localhost:8080',
  );
}
