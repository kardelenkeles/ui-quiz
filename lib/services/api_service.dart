import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5000';

  static Future<Map<String, dynamic>> generateQuiz(
    String text, {
    String language = 'auto',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate-quiz'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'language': language}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  static Future<String> detectLanguage(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/detect-language'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['language'];
      } else {
        return 'en'; // Fallback to English
      }
    } catch (e) {
      return 'en';
    }
  }
}
