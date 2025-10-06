import 'package:ui_quiz/services/quota_service.dart';
import 'package:ui_quiz/services/openai_service.dart';
import 'package:ui_quiz/services/quiz_storage_service.dart';
import 'package:ui_quiz/services/auth_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Servis örnekleri
  QuotaService? _quotaService;
  OpenAIService? _openAIService;
  QuizStorageService? _quizStorageService;
  AuthService? _authService;

  // OpenAI API Key (environment'dan alınacak)
  String? _openAIApiKey;

  /// Servisleri initialize et
  void initialize({required String openAIApiKey}) {
    _openAIApiKey = openAIApiKey;

    _quotaService = QuotaService();
    _openAIService = OpenAIService(apiKey: openAIApiKey);
    _quizStorageService = QuizStorageService();
    _authService = AuthService();
  }

  /// QuotaService'i al
  QuotaService get quotaService {
    if (_quotaService == null) {
      throw Exception(
        'ServiceLocator not initialized. Call initialize() first.',
      );
    }
    return _quotaService!;
  }

  /// OpenAIService'i al
  OpenAIService get openAIService {
    if (_openAIService == null) {
      throw Exception(
        'ServiceLocator not initialized. Call initialize() first.',
      );
    }
    return _openAIService!;
  }

  /// QuizStorageService'i al
  QuizStorageService get quizStorageService {
    if (_quizStorageService == null) {
      throw Exception(
        'ServiceLocator not initialized. Call initialize() first.',
      );
    }
    return _quizStorageService!;
  }

  /// AuthService'i al
  AuthService get authService {
    if (_authService == null) {
      throw Exception(
        'ServiceLocator not initialized. Call initialize() first.',
      );
    }
    return _authService!;
  }

  /// API anahtarını güncelle
  void updateOpenAIApiKey(String newApiKey) {
    _openAIApiKey = newApiKey;
    _openAIService = OpenAIService(apiKey: newApiKey);
  }

  /// Servisleri temizle (logout durumunda)
  void clear() {
    // Gerekirse servis durumlarını temizle
    // Şimdilik sadece referansları koru
  }

  /// Sistem sağlık kontrolü
  Future<Map<String, bool>> healthCheck() async {
    final results = <String, bool>{};

    try {
      // OpenAI API kontrolü
      results['openAI'] = await _openAIService?.testApiKey() ?? false;
    } catch (e) {
      results['openAI'] = false;
    }

    try {
      // Quota service kontrolü (basit test)
      await _quotaService?.getRemainingQuota();
      results['quota'] = true;
    } catch (e) {
      results['quota'] = false;
    }

    try {
      // Storage service kontrolü (basit test)
      await _quizStorageService?.getUserStats();
      results['storage'] = true;
    } catch (e) {
      results['storage'] = false;
    }

    try {
      // Auth service kontrolü
      _authService?.currentUser();
      results['auth'] = true;
    } catch (e) {
      results['auth'] = false;
    }

    return results;
  }
}

// Global erişim için shortcut
ServiceLocator get services => ServiceLocator();
