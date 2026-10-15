import 'package:firebase_auth/firebase_auth.dart';

import 'app_logger.dart';

/// Teknik hataları kullanıcıya gösterilebilecek, kararlı mesajlara dönüştürür.
abstract final class AppErrorHandler {
  static String message(
    Object error, {
    StackTrace? stackTrace,
    String fallback = 'Bir sorun oluştu. Lütfen tekrar deneyin.',
    String? reason,
  }) {
    AppLogger.error(error, stackTrace: stackTrace, reason: reason);

    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Geçerli bir e-posta adresi girin.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' => 'E-posta veya şifre hatalı.',
        'email-already-in-use' => 'Bu e-posta adresi zaten kullanılıyor.',
        'weak-password' => 'Daha güçlü bir şifre seçin.',
        'too-many-requests' =>
          'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin.',
        'network-request-failed' =>
          'İnternet bağlantınızı kontrol edip tekrar deneyin.',
        'requires-recent-login' =>
          'Bu işlem için yeniden giriş yapmanız gerekiyor.',
        _ => fallback,
      };
    }

    final normalized = error.toString().toLowerCase();
    if (normalized.contains('timeout') || normalized.contains('socket')) {
      return 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }
    if (normalized.contains('429') || normalized.contains('quota')) {
      return 'İstek sınırına ulaşıldı. Lütfen biraz sonra tekrar deneyin.';
    }
    return fallback;
  }
}
