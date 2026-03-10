class Constants {
  // Use --dart-define=GEMINI_API_KEY=your_key or env.json
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',
  );
}
