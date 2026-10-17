import 'package:flutter/foundation.dart';

class AppConfig {
  /// Set after RevenueCat has been configured successfully for the platform.
  /// This prevents auth listeners from calling the SDK before initialization.
  static bool revenueCatConfigured = false;
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// Override per environment with --dart-define=API_BASE_URL=... or
  /// --dart-define-from-file=....
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-7eiuli4vcq-uc.a.run.app',
  );

  /// This domain must be listed in Firebase Auth's authorized domains.
  static const String authContinueUrl = String.fromEnvironment(
    'AUTH_CONTINUE_URL',
    defaultValue: 'https://quiz-ai-242b4.firebaseapp.com/finishSignIn',
  );

  /// Set only for a custom Firebase Hosting domain. Firebase selects its
  /// default firebaseapp.com domain when this is empty.
  static const String authLinkDomain = String.fromEnvironment(
    'AUTH_LINK_DOMAIN',
  );

  static const String androidPackageName = 'com.kk.ui_quiz';
  static const String iosBundleId = 'com.kk.uiQuiz';

  // RevenueCat public SDK keys are build configuration, not server secrets.
  static const String revenueCatAndroidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const String revenueCatIosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );

  static bool get isProduction => kReleaseMode || environment == 'production';

  static Future<void> initialize() async {
    _validateHttpUrl('API_BASE_URL', apiBaseUrl);
    _validateHttpUrl('AUTH_CONTINUE_URL', authContinueUrl);

    if (isProduction) {
      _requireHttps('API_BASE_URL', apiBaseUrl);
      _requireHttps('AUTH_CONTINUE_URL', authContinueUrl);

      if (apiBaseUrl.contains('localhost') ||
          authContinueUrl.contains('localhost')) {
        throw StateError('Production URLs cannot point to localhost.');
      }
    }
  }

  static void validateRevenueCatKey({
    required String platform,
    required String apiKey,
  }) {
    if (isProduction && apiKey.trim().isEmpty) {
      throw StateError(
        'REVENUECAT_${platform.toUpperCase()}_API_KEY is required in production.',
      );
    }
  }

  static void _validateHttpUrl(String name, String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw StateError('$name must be an absolute HTTP(S) URL.');
    }
  }

  static void _requireHttps(String name, String value) {
    if (Uri.parse(value).scheme != 'https') {
      throw StateError('$name must use HTTPS in production.');
    }
  }
}
