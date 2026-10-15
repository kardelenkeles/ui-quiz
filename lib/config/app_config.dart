class AppConfig {
  static const String apiBaseUrl = 'https://api-7eiuli4vcq-uc.a.run.app';

  /// Backend URL fallback for local development.
  static String get backendUrl => 'http://localhost:5000';

  /// No-op initialize (previously loaded .env). Kept for API compatibility.
  static Future<void> initialize() async {}
}
