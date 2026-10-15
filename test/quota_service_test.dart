import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ui_quiz/services/quota_service.dart';

void main() {
  group('QuotaService', () {
    test('sends Firebase bearer token and reads free quota', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'plan': 'free', 'dailyRemaining': 2}),
          200,
        );
      });
      final service = QuotaService(
        client: client,
        baseUrl: 'https://api.example.test',
        tokenProvider: () async => 'id-token',
      );

      expect(await service.canCreateQuiz(), isTrue);
      expect(captured.url.toString(), 'https://api.example.test/quota');
      expect(captured.headers['Authorization'], 'Bearer id-token');
    });

    test('rejects requests when no signed-in token exists', () async {
      final service = QuotaService(
        client: MockClient((_) async => http.Response('{}', 200)),
        tokenProvider: () async => null,
      );

      await expectLater(service.getRemainingQuota(), throwsA(isA<Exception>()));
    });

    test('uses premium token balance as the creation decision', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'plan': 'premium', 'tokensRemaining': 0}),
          200,
        ),
      );
      final service = QuotaService(
        client: client,
        tokenProvider: () async => 'token',
      );

      expect(await service.canCreateQuiz(), isFalse);
    });
  });
}
