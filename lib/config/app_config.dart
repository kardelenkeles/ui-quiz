class AppConfig {
  /// OpenAI API key is fetched at runtime from Cloud Functions
  /// and injected into services via ServiceLocator.
  static String get openAiApiKey => '';

  /// Firebase API key comes from firebase_options (auto-generated) so
  /// we don't load it from a local .env file.
  static String get firebaseApiKey => '';

  /// Backend URL fallback for local development.
  static String get backendUrl => 'http://localhost:5000';

  /// No-op initialize (previously loaded .env). Kept for API compatibility.
  static Future<void> initialize() async {}
}
