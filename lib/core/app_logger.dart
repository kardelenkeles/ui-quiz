import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

typedef ErrorReporter =
    Future<void> Function(
      Object error,
      StackTrace stackTrace, {
      required bool fatal,
      String? reason,
    });

/// Uygulamadaki tanılama çıktısını ve hata raporlamayı tek noktada toplar.
abstract final class AppLogger {
  static ErrorReporter? _errorReporter;

  static void configure({ErrorReporter? errorReporter}) {
    _errorReporter = errorReporter;
  }

  static void debug(Object? message, {String name = 'ui_quiz'}) {
    if (kDebugMode) {
      developer.log('$message', name: name);
    }
  }

  static void info(Object? message, {String name = 'ui_quiz'}) {
    developer.log('$message', name: name, level: 800);
  }

  static void warning(Object? message, {String name = 'ui_quiz'}) {
    developer.log('$message', name: name, level: 900);
  }

  static void error(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
    String name = 'ui_quiz',
  }) {
    final trace = stackTrace ?? StackTrace.current;
    developer.log(
      reason ?? error.toString(),
      name: name,
      level: 1000,
      error: error,
      stackTrace: trace,
    );
    final reporter = _errorReporter;
    if (reporter != null) {
      reporter(error, trace, fatal: fatal, reason: reason).ignore();
    }
  }
}
