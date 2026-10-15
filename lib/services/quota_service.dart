import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ui_quiz/config/app_config.dart';

abstract interface class QuotaReader {
  Future<Map<String, dynamic>> getRemainingQuota();
}

class QuotaService implements QuotaReader {
  QuotaService({
    FirebaseAuth? auth,
    http.Client? client,
    Future<String?> Function()? tokenProvider,
    String? baseUrl,
  }) : _auth = auth,
       _client = client ?? http.Client(),
       _tokenProvider = tokenProvider,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final FirebaseAuth? _auth;
  final http.Client _client;
  final Future<String?> Function()? _tokenProvider;
  final String _baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = _tokenProvider != null
        ? await _tokenProvider()
        : await (_auth ?? FirebaseAuth.instance).currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please sign in first.');
    }
    return {'Authorization': 'Bearer $token'};
  }

  /// The backend is authoritative for both quota checks and usage writes.
  @override
  Future<Map<String, dynamic>> getRemainingQuota() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/quota'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to read quota (${response.statusCode}).');
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid quota response.');
    }
    return data;
  }

  Future<bool> canCreateQuiz() async {
    final quota = await getRemainingQuota();
    if (quota['plan'] == 'premium') {
      return (quota['tokensRemaining'] as num? ?? 0) > 0;
    }
    return (quota['dailyRemaining'] as num? ?? 0) > 0;
  }
}
