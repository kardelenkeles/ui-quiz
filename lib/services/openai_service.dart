import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  final String _apiKey;
  // Optional backend proxy base URL (your Cloud Function proxy)
  static const String _backendProxyBase = 'https://api-7eiuli4vcq-uc.a.run.app';
  // Always use backend proxy in production builds
  bool get _useProxy => true;
  Future<String?> _currentIdToken() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  OpenAIService({required String apiKey}) : _apiKey = apiKey;

  /// Quiz üret
  Future<List<Map<String, dynamic>>> generateQuiz({
    required String topic,
    required int questionCount,
    String difficulty = 'orta',
    String language = 'Turkish',
    String? fileContent,
  }) async {
    try {
      // If a file content is provided and it's long, summarize it first (chunking)
      int totalTokensUsed = 0;
      String? promptFileContent = fileContent;

      if (fileContent != null && fileContent.trim().isNotEmpty) {
        // Heuristic: if the file content is large, summarize in chunks
        const int longThreshold = 8000; // characters, heuristic
        if (fileContent.length > longThreshold) {
          final summary = await _summarizeText(fileContent);
          promptFileContent = summary;
        }
      }

      final prompt = _buildQuizPrompt(
        topic,
        questionCount,
        difficulty,
        language,
        fileContent: promptFileContent,
      );

      // Select model based on prompt size
      final model = _selectModelForContent(prompt);
      final temperature = 0.2; // deterministic JSON output

      final bodyPayload = {
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content':
                'Sen bir quiz oluşturma uzmanısın. Verilen konularda eğitici ve kaliteli sorular hazırlarsın.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': _estimateMaxTokens(questionCount),
        'temperature': temperature,
      };

      if (_useProxy) {
        final idToken = await _currentIdToken();
        print(
          'ID Token: ${idToken != null ? 'Present (${idToken.substring(0, 20)}...)' : 'NULL'}',
        );
        print(
          'Current user: ${fb_auth.FirebaseAuth.instance.currentUser?.uid}',
        );

        if (idToken == null || idToken.isEmpty) {
          throw Exception(
            'Lütfen önce giriş yapın. Premium hesapla devam etmek için kayıt olun.',
          );
        }

        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        };

        print('Request URL: $_backendProxyBase/openai/chat');
        print('Headers: $headers');

        final response = await http.post(
          Uri.parse('$_backendProxyBase/openai/chat'),
          headers: headers,
          body: json.encode(bodyPayload),
        );
        // use response below
        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            final content = data['choices'][0]['message']['content'] as String;
            final tokensUsed =
                (data['usage'] != null && data['usage']['total_tokens'] != null)
                ? data['usage']['total_tokens'] as int
                : 0;

            totalTokensUsed += tokensUsed;

            final questions = _parseQuizResponse(content);
            if (totalTokensUsed > 0) await _recordTokenUsage(totalTokensUsed);
            return questions;
          } catch (e) {
            print('Response decode error: $e');
            print('Response body: ${response.body}');
            print('Response headers: ${response.headers}');
            throw Exception(
              'Invalid JSON response from server: ${response.body.substring(0, 100)}...',
            );
          }
        } else {
          print('HTTP Error ${response.statusCode}');
          print('Response body: ${response.body}');
          print('Response headers: ${response.headers}');
          try {
            final errorData = json.decode(response.body);
            throw Exception(
              'OpenAI API Error: ${errorData['error']['message']}',
            );
          } catch (e) {
            throw Exception('HTTP ${response.statusCode}: ${response.body}');
          }
        }
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(bodyPayload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final tokensUsed =
            (data['usage'] != null && data['usage']['total_tokens'] != null)
            ? data['usage']['total_tokens'] as int
            : 0;

        totalTokensUsed += tokensUsed;

        // JSON parse et
        final questions = _parseQuizResponse(content);

        // Token kullanımını kaydet
        if (totalTokensUsed > 0) await _recordTokenUsage(totalTokensUsed);

        return questions;
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception('OpenAI API Error: ${errorData['error']['message']}');
        } catch (e) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      print('Error generating quiz: $e');
      rethrow;
    }
  }

  /// Basit chunk + summarize akışı. Uzun metinler için özet döner.
  Future<String> _summarizeText(String text) async {
    final chunks = _chunkText(text, 3000);
    final summaries = <String>[];

    for (final chunk in chunks) {
      try {
        final summarizePayload = {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Sen kısa ve öz özet çıkarma konusunda uzmansın.',
            },
            {
              'role': 'user',
              'content':
                  'Aşağıdaki metni Türkiye Türkçesi olarak kısaca özetle. Anahtar noktaları ve önemli terimleri koru. Sadece düz metin döndür. Metin:\n\n$chunk',
            },
          ],
          'max_tokens': 800,
          'temperature': 0.2,
        };

        if (_useProxy) {
          final idToken = await _currentIdToken();
          final headers = <String, String>{'Content-Type': 'application/json'};
          if (idToken != null && idToken.isNotEmpty)
            headers['Authorization'] = 'Bearer $idToken';
          final response = await http.post(
            Uri.parse('$_backendProxyBase/openai/chat'),
            headers: headers,
            body: json.encode(summarizePayload),
          );
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final content = data['choices'][0]['message']['content'] as String;
            summaries.add(content.trim());
            continue;
          } else {
            summaries.add(
              chunk.substring(0, chunk.length > 1000 ? 1000 : chunk.length),
            );
            continue;
          }
        }

        final response = await http.post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: json.encode(summarizePayload),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final content = data['choices'][0]['message']['content'] as String;
          summaries.add(content.trim());
        } else {
          // Eğer özetleme başarısızsa, fallback: chunk'ın kendisini ekle
          summaries.add(
            chunk.substring(0, chunk.length > 1000 ? 1000 : chunk.length),
          );
        }
      } catch (e) {
        summaries.add(
          chunk.substring(0, chunk.length > 1000 ? 1000 : chunk.length),
        );
      }
    }

    return summaries.join('\n');
  }

  List<String> _chunkText(String text, int size) {
    final parts = <String>[];
    int index = 0;
    while (index < text.length) {
      final end = (index + size < text.length) ? index + size : text.length;
      parts.add(text.substring(index, end));
      index = end;
    }
    return parts;
  }

  String _selectModelForContent(String prompt) {
    // Heuristics: use gpt-3.5-turbo for short prompts, gpt-4 for longer or complex prompts
    final len = prompt.length;
    if (len > 15000) return 'gpt-4';
    if (len > 7000) return 'gpt-4';
    return 'gpt-3.5-turbo';
  }

  /// Quiz prompt oluştur
  String _buildQuizPrompt(
    String topic,
    int questionCount,
    String difficulty,
    String language, {
    String? fileContent,
  }) {
    final sb = StringBuffer();
    // Eğer kullanıcı bir konu yazmamış ama dosya içeriği varsa,
    // soruları doğrudan dokümandaki içeriğe göre oluşturmasını iste.
    if (topic.trim().isEmpty &&
        fileContent != null &&
        fileContent.trim().isNotEmpty) {
      sb.writeln(
        '$language dilinde, aşağıdaki dokümanda verilen içeriğe dayanarak $questionCount adet çoktan seçmeli soru oluştur.',
      );
    } else {
      sb.writeln(
        '$language dilinde "$topic" konusunda $questionCount adet çoktan seçmeli soru oluştur.',
      );
    }
    sb.writeln('Zorluk seviyesi: $difficulty');
    sb.writeln('Kurallar:');
    sb.writeln('1) Her soru 4 seçenekli olmalı (A, B, C, D)');
    sb.writeln('2) Sorular anlaşılır ve net olmalı');
    sb.writeln('3) Seçenekler makul uzunlukta olmalı');
    sb.writeln('4) Sadece bir doğru cevap olmalı');
    sb.writeln('5) Yanıltıcı ama makul seçenekler ekle');
    sb.writeln(
      'Çıktı formatı örneği: [{"question":"Soru metni?","options":[{"letter":"A","text":"Seçenek A"},{"letter":"B","text":"Seçenek B"},{"letter":"C","text":"Seçenek C"},{"letter":"D","text":"Seçenek D"}],"correctAnswer":"A"}]',
    );
    sb.writeln(
      'Sadece JSON array dön. Başında veya sonunda kod bloğu işaretleri veya ekstra metin olmamalı.',
    );

    if (fileContent != null && fileContent.trim().isNotEmpty) {
      final max = 30000;
      final snippet = fileContent.length > max
          ? fileContent.substring(0, max)
          : fileContent;
      sb.writeln('\n--- DOKUMAN ICERİĞI BASLANGİÇI ---');
      sb.writeln(snippet);
      sb.writeln('\n--- DOKUMAN ICERİĞI BITİSI ---');
      sb.writeln(
        'Use the document content above to generate questions where relevant.',
      );
    }

    return sb.toString();
  }

  /// Quiz yanıtını parse et
  List<Map<String, dynamic>> _parseQuizResponse(String content) {
    try {
      // Temizle ve formatla
      content = content.trim();

      // Markdown kod bloğu varsa kaldır
      if (content.startsWith('```json')) {
        content = content.substring(7);
      } else if (content.startsWith('```')) {
        content = content.substring(3);
      }
      if (content.endsWith('```')) {
        content = content.substring(0, content.length - 3);
      }

      content = content.trim();

      // JSON başlangıç ve bitişini bul
      final startIndex = content.indexOf('[');
      final endIndex = content.lastIndexOf(']') + 1;

      if (startIndex == -1 || endIndex == 0) {
        throw Exception('Invalid JSON format in response');
      }

      final jsonString = content.substring(startIndex, endIndex);

      // Geçersiz karakterleri temizle
      final cleanJsonString = jsonString
          .replaceAll(
            RegExp(r'[\u0000-\u001F]'),
            '',
          ) // Kontrol karakterlerini kaldır
          .replaceAll(
            RegExp(r'[\u2028\u2029]'),
            '',
          ); // Satır ayırıcıları kaldır

      final List<dynamic> jsonData = json.decode(cleanJsonString);

      return jsonData.map((item) {
        if (item is! Map<String, dynamic>) {
          throw Exception('Question item is not a valid object');
        }

        final question = item;

        // Validation
        if (!question.containsKey('question') ||
            !question.containsKey('options') ||
            !question.containsKey('correctAnswer')) {
          throw Exception(
            'Missing required fields in question: ${question.keys}',
          );
        }

        if (!(question['options'] is List)) {
          throw Exception('Options is not a valid array');
        }

        final options = question['options'] as List<dynamic>;
        if (options.isEmpty || options.length != 4) {
          throw Exception(
            'Each question must have exactly 4 options (found: ${options.length})',
          );
        }

        // Format kontrolü
        for (final option in options) {
          if (!(option is Map<String, dynamic>)) {
            throw Exception('Option is not a valid object');
          }
          final opt = option;
          if (!opt.containsKey('letter') || !opt.containsKey('text')) {
            throw Exception('Invalid option format: missing letter or text');
          }
          if (!(opt['letter'] is String) || !(opt['text'] is String)) {
            throw Exception('Option letter and text must be strings');
          }
        }

        return {
          'question': question['question'] as String,
          'options': options
              .map(
                (opt) => {
                  'letter': opt['letter'] as String,
                  'text': opt['text'] as String,
                },
              )
              .toList(),
          'correctAnswer': question['correctAnswer'] as String,
          'selectedAnswer': null, // Flutter tarafında kullanılacak
        };
      }).toList();
    } catch (e) {
      print('Error parsing quiz response: $e');
      print('Content: $content');
      throw Exception('Failed to parse quiz data: $e');
    }
  }

  /// Max token sayısını tahmin et
  int _estimateMaxTokens(int questionCount) {
    // Her soru için ortalama 200 token
    return questionCount * 200 + 500; // 500 token buffer
  }

  /// Token kullanımını kaydet
  Future<void> _recordTokenUsage(int tokensUsed) async {
    try {
      // App settings'e genel istatistik ekle
      await _firestore.collection('app_settings').doc('usage_stats').set({
        'totalTokensUsed': FieldValue.increment(tokensUsed),
        'totalQuizzes': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error recording token usage: $e');
      // Token kaydı başarısız olsa da quiz oluşturma devam etsin
    }
  }

  /// Token kullanım tahminini al (quiz oluşturmadan önce)
  int estimateTokensForQuiz({
    required String topic,
    required int questionCount,
    String difficulty = 'orta',
    String? fileContent,
  }) {
    // Basit tahmin: konu uzunluğu + soru sayısı bazlı
    final topicLength = topic.length;
    final baseTokens = 100; // Sistem prompt
    final questionTokens = questionCount * 150; // Her soru için ortalama
    final topicTokens = (topicLength / 4).ceil(); // 4 karakter ≈ 1 token
    final fileTokens = fileContent != null && fileContent.isNotEmpty
        ? (fileContent.length / 4).ceil()
        : 0; // kaba tahmin: 4 karakter ≈ 1 token
    final difficultyTokens = difficulty == 'zor'
        ? 50
        : 0; // Zor sorular daha fazla token

    return baseTokens +
        questionTokens +
        topicTokens +
        fileTokens +
        difficultyTokens;
  }

  /// API anahtarının geçerli olup olmadığını test et
  Future<bool> testApiKey() async {
    try {
      if (_useProxy) {
        final idToken = await _currentIdToken();
        final headers = <String, String>{};
        if (idToken != null && idToken.isNotEmpty)
          headers['Authorization'] = 'Bearer $idToken';
        final response = await http.get(
          Uri.parse('$_backendProxyBase/openai/models'),
          headers: headers,
        );
        return response.statusCode == 200;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error testing API key: $e');
      return false;
    }
  }

  /// Kullanılabilir modelleri al
  Future<List<String>> getAvailableModels() async {
    try {
      if (_useProxy) {
        final idToken = await _currentIdToken();
        final headers = <String, String>{};
        if (idToken != null && idToken.isNotEmpty)
          headers['Authorization'] = 'Bearer $idToken';
        final response = await http.get(
          Uri.parse('$_backendProxyBase/openai/models'),
          headers: headers,
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final models = data['data'] as List<dynamic>;

          return models
              .where((model) => model['id'].toString().contains('gpt'))
              .map((model) => model['id'].toString())
              .toList();
        }
        return ['gpt-3.5-turbo']; // Fallback
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['data'] as List<dynamic>;

        return models
            .where((model) => model['id'].toString().contains('gpt'))
            .map((model) => model['id'].toString())
            .toList();
      }

      return ['gpt-3.5-turbo']; // Fallback
    } catch (e) {
      print('Error getting available models: $e');
      return ['gpt-3.5-turbo']; // Fallback
    }
  }

  /// Quiz kalitesini değerlendir (opsiyonel - gelişmiş özellik)
  Future<Map<String, dynamic>> evaluateQuizQuality(
    List<Map<String, dynamic>> questions,
  ) async {
    try {
      final questionsText = questions
          .map((q) => q['question'] as String)
          .join('\n');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Sen bir eğitim uzmanısın. Quiz sorularının kalitesini değerlendirirsin.',
            },
            {
              'role': 'user',
              'content':
                  '''
Aşağıdaki quiz sorularını değerlendir:

$questionsText

1-10 arası puan ver ve kısa geri bildirim sağla.
JSON formatında yanıt ver:
{
  "score": 8,
  "feedback": "Genel olarak iyi sorular, ancak 2. soru biraz belirsiz."
}
''',
            },
          ],
          'max_tokens': 200,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // JSON parse et
        final evaluation = json.decode(content);
        return evaluation;
      }

      return {'score': 7, 'feedback': 'Değerlendirme yapılamadı'};
    } catch (e) {
      print('Error evaluating quiz quality: $e');
      return {'score': 7, 'feedback': 'Değerlendirme yapılamadı'};
    }
  }
}
