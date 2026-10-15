import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ui_quiz/config/app_config.dart';

class QuotaService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please sign in first.');
    }
    return {'Authorization': 'Bearer $token'};
  }

  /// The backend is authoritative for both quota checks and usage writes.
  Future<Map<String, dynamic>> getRemainingQuota() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/quota'),
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
