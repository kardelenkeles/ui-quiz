import 'package:firebase_auth/firebase_auth.dart';

import 'app_logger.dart';

/// Teknik hataları kullanıcıya gösterilebilecek, kararlı mesajlara dönüştürür.
abstract final class AppErrorHandler {
  static String message(
    Object error, {
    StackTrace? stackTrace,
    String fallback = 'Something went wrong. Please try again.',
    String? reason,
  }) {
    AppLogger.error(error, stackTrace: stackTrace, reason: reason);

    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' => 'The email or password is incorrect.',
        'email-already-in-use' => 'This email address is already in use.',
        'weak-password' => 'Choose a stronger password.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        'requires-recent-login' =>
          'Please sign in again to complete this action.',
        _ => fallback,
      };
    }

    final normalized = error.toString().toLowerCase();
    if (normalized.contains('timeout') || normalized.contains('socket')) {
      return 'The connection timed out. Please try again.';
    }
    if (normalized.contains('429') || normalized.contains('quota')) {
      return 'The request limit was reached. Please try again later.';
    }
    return fallback;
  }
}
