import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get openAiApiKey {
    return dotenv.get('OPENAI_API_KEY', fallback: '');
  }

  static String get firebaseApiKey {
    return dotenv.get('FIREBASE_API_KEY', fallback: '');
  }

  static String get backendUrl {
    return dotenv.get('BACKEND_URL', fallback: 'http://localhost:5000');
  }

  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }
}
