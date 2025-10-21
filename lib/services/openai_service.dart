import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  final String _apiKey;
  static const String _backendProxyBase = 'https://api-7eiuli4vcq-uc.a.run.app';
  bool get _useProxy => true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  OpenAIService({required String apiKey}) : _apiKey = apiKey;

  Future<String?> _currentIdToken() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// Quiz üret
  /// NOT: Geriye döndürülen Map, üretilen soruları ('questions') ve toplam token kullanımını ('tokensUsed') içerir.
  Future<Map<String, dynamic>> generateQuiz({
    required String topic,
    required int questionCount,
    String difficulty = 'orta',
    String language = 'Turkish',
    String? fileContent,
    String? filePath,
  }) async {
    try {
      const int batchSize = 5; // gpt-5-mini için önerilen max soru sayısı
      final allQuestions = <Map<String, dynamic>>[];
      int remaining = questionCount;
      int generatedSoFar = 0;
      int totalTokensUsed = 0;

      // Eğer istenen soru sayısı batch boyutundan küçük veya eşitse, tek batch ile devam et
      if (questionCount <= batchSize) {
        final result = await _generateQuizBatch(
          topic: topic,
          questionCount: questionCount,
          difficulty: difficulty,
          language: language,
          fileContent: fileContent,
          filePath: filePath,
        );
        allQuestions.addAll(result['questions'] as List<Map<String, dynamic>>);
        totalTokensUsed += result['tokensUsed'] as int;

        if (totalTokensUsed > 0) await _recordTokenUsage(totalTokensUsed);

        return {'questions': allQuestions, 'tokensUsed': totalTokensUsed};
      }

      // Batching mantığı
      print(
        'Batching quiz generation: $questionCount questions in batches of $batchSize',
      );

      while (remaining > 0) {
        final batchCount = remaining > batchSize ? batchSize : remaining;
        print(
          'Generating batch: $batchCount questions (${generatedSoFar + batchCount}/$questionCount total)',
        );

        final batchResult = await _generateQuizBatch(
          topic: topic,
          questionCount: batchCount,
          difficulty: difficulty,
          language: language,
          fileContent: fileContent,
          filePath: filePath,
        );

        allQuestions.addAll(
          batchResult['questions'] as List<Map<String, dynamic>>,
        );
        totalTokensUsed += batchResult['tokensUsed'] as int;
        remaining -= batchCount;
        generatedSoFar += batchCount;
      }

      if (totalTokensUsed > 0) await _recordTokenUsage(totalTokensUsed);

      return {'questions': allQuestions, 'tokensUsed': totalTokensUsed};
    } catch (e) {
      print('Error generating quiz: $e');
      rethrow;
    }
  }

  /// Generate a single batch of quiz questions
  Future<Map<String, dynamic>> _generateQuizBatch({
    required String topic,
    required int questionCount,
    String difficulty = 'orta',
    String language = 'Turkish',
    String? fileContent,
    String? filePath,
  }) async {
    try {
      int batchTokensUsed = 0;
      String? promptFileContent = fileContent;

      // ----------------------------------------------------
      // UZUN METİN YÖNETİMİ: Chunking/Summarization
      // ----------------------------------------------------
      if (fileContent != null && fileContent.trim().isNotEmpty) {
        const int longThreshold = 8000;
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

      // ----------------------------------------------------
      // GÖRSEL (VISION) YÖNETİMİ
      // ----------------------------------------------------
      bool isImageFile = false;
      String? imageBase64;
      String? imageMimeType;

      if (filePath != null && filePath.trim().isNotEmpty) {
        final lowerPath = filePath.toLowerCase();
        if (lowerPath.endsWith('.jpg') ||
            lowerPath.endsWith('.jpeg') ||
            lowerPath.endsWith('.png') ||
            lowerPath.endsWith('.gif') ||
            lowerPath.endsWith('.webp')) {
          try {
            final imageFile = File(filePath);
            final bytes = await imageFile.readAsBytes();

            // NOT: YÜKSEK ÇÖZÜNÜRLÜKLÜ GÖRSELLER API'YE GÖNDERİLMEDEN ÖNCE SIKIŞTIRILMALIDIR!
            imageBase64 = base64Encode(bytes);

            if (lowerPath.endsWith('.png')) {
              imageMimeType = 'image/png';
            } else if (lowerPath.endsWith('.gif')) {
              imageMimeType = 'image/gif';
            } else if (lowerPath.endsWith('.webp')) {
              imageMimeType = 'image/webp';
            } else {
              imageMimeType = 'image/jpeg';
            }

            isImageFile = true;
          } catch (e) {
            print('Failed to read image file: $e');
            isImageFile = false;
          }
        }
      }

      // Vision için gpt-4o, Metin için gpt-5-mini
      final model = isImageFile ? 'gpt-4o' : 'gpt-5-mini';

      final Map<String, dynamic> bodyPayload;

      final int estimatedMaxTokens = _estimateMaxTokens(questionCount);

      if (isImageFile && imageBase64 != null) {
        bodyPayload = {
          'model': model, // gpt-4o
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert quiz creator. Generate educational, high-quality multiple-choice questions based on the provided image and instructions. Output ONLY the JSON array.',
            },
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$imageMimeType;base64,$imageBase64',
                    'detail': 'auto', // Timeout riskini azaltmak için 'auto'
                  },
                },
              ],
            },
          ],
          'max_completion_tokens': estimatedMaxTokens,
        };
      } else {
        bodyPayload = {
          'model': model, // gpt-5-mini
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert quiz creator. Generate educational, high-quality multiple-choice questions on the provided topics. Output ONLY the JSON array.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_completion_tokens': estimatedMaxTokens,
        };
      }

      // ----------------------------------------------------
      // API ÇAĞRISI VE YENİDEN DENEME MANTIĞI
      // ----------------------------------------------------
      final response = await _executeApiCall(
        endpoint: '/chat/completions',
        payload: bodyPayload,
        questionCount: questionCount,
        isProxy: _useProxy,
      );

      batchTokensUsed = response['tokensUsed'] as int;

      final questions = _parseQuizResponse(response['content'] as String);

      return {'questions': questions, 'tokensUsed': batchTokensUsed};
    } catch (e) {
      print('Error generating quiz batch: $e');
      rethrow;
    }
  }

  /// API çağrısını gerçekleştirir (Proxy veya Direkt). Yeniden deneme ve token kaydını içerir.
  Future<Map<String, dynamic>> _executeApiCall({
    required String endpoint,
    required Map<String, dynamic> payload,
    required int questionCount,
    required bool isProxy,
  }) async {
    int totalTokensUsed = 0;

    Future<http.Response> _makeRequest(
      Map<String, dynamic> currentPayload,
    ) async {
      if (isProxy) {
        final idToken = await _currentIdToken();
        if (idToken == null || idToken.isEmpty) {
          throw Exception('Lütfen önce giriş yapın.');
        }
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        };
        return http.post(
          Uri.parse('$_backendProxyBase/openai/chat'),
          headers: headers,
          body: json.encode(currentPayload),
        );
      } else {
        return http.post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: json.encode(currentPayload),
        );
      }
    }

    Map<String, dynamic> _parseResponse(http.Response response) {
      if (response.statusCode != 200) {
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            'OpenAI API Error ${response.statusCode}: ${errorData['error']['message']}',
          );
        } catch (_) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }

      final data = json.decode(response.body);

      final choice = (data['choices'] is List && data['choices'].isNotEmpty)
          ? data['choices'][0] as Map<String, dynamic>
          : null;

      String? content;
      if (choice != null &&
          choice['message'] != null &&
          choice['message']['content'] != null) {
        content = choice['message']['content'] as String;
      } else if (choice != null && data['text'] != null) {
        content = data['text'] as String;
      }

      final tokens =
          (data['usage'] != null && data['usage']['total_tokens'] != null)
          ? data['usage']['total_tokens'] as int
          : 0;

      final finishReason =
          (choice != null && choice.containsKey('finish_reason'))
          ? choice['finish_reason']
          : null;

      return {
        'content': content,
        'tokensUsed': tokens,
        'finishReason': finishReason,
      };
    }

    final payloadCopy = Map<String, dynamic>.from(payload);

    // 1. Ana İstek
    var response = await _makeRequest(payloadCopy);
    var parsed = _parseResponse(response);
    totalTokensUsed += parsed['tokensUsed'] as int;

    String? content = parsed['content'] as String?;
    String? finishReason = parsed['finishReason'] as String?;

    // 2. Yeniden Deneme (Kesilme veya Boş İçerik Durumunda)
    if (content == null || content.trim().isEmpty || finishReason == 'length') {
      print(
        'Assistant content empty or truncated (finish_reason=$finishReason). Attempting one retry with larger max tokens.',
      );

      final origMax = payloadCopy.containsKey('max_completion_tokens')
          ? (payloadCopy['max_completion_tokens'] as int)
          : (payloadCopy.containsKey('max_tokens')
                ? (payloadCopy['max_tokens'] as int)
                : _estimateMaxTokens(questionCount));

      final increased = _clampToModelLimit(((origMax + 1500).toInt()));

      payloadCopy['max_completion_tokens'] = increased;

      try {
        response = await _makeRequest(payloadCopy);
        parsed = _parseResponse(response);
        totalTokensUsed += parsed['tokensUsed'] as int;
        content = parsed['content'] as String?;
        finishReason = parsed['finishReason'] as String?;
      } catch (e) {
        print('Retry request failed: $e');
      }

      // 3. Kurtarma İsteği (Rescue Request)
      if (content == null || content.trim().isEmpty) {
        print('Assistant still empty after retry. Sending rescue follow-up.');
        final rescuePayload = {
          'model': payloadCopy['model'],
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert quiz creator. Output ONLY the JSON array of questions exactly as requested previously. Do not include any explanation or code fences.',
            },
            {
              'role': 'user',
              'content':
                  'Previous response was empty or truncated. Please output the quiz as a JSON array exactly in the format: [{"question":"...","options":[{"letter":"A","text":"..."},...],"correctAnswer":"A"}, ...]. Return only the JSON array.',
            },
          ],
          'max_completion_tokens': _clampToModelLimit(
            _estimateMaxTokens(questionCount),
          ),
        };

        try {
          response = await _makeRequest(rescuePayload);
          parsed = _parseResponse(response);
          totalTokensUsed += parsed['tokensUsed'] as int;
          content = parsed['content'] as String?;
        } catch (e) {
          print('Rescue request failed: $e');
          throw Exception(
            'API’dan quiz üretilemedi. İçerik çok zor/kısa veya sunucu hatası.',
          );
        }
      }
    }

    if (content == null || content.trim().isEmpty) {
      throw Exception(
        'Invalid JSON response from server: assistant returned empty content after all attempts.',
      );
    }

    return {'content': content, 'tokensUsed': totalTokensUsed};
  }

  /// Basit chunk + summarize akışı. Uzun metinler için özet döner.
  Future<String> _summarizeText(String text) async {
    final chunks = _chunkText(text, 3000);
    final summaries = <String>[];

    for (final chunk in chunks) {
      try {
        final summarizePayload = {
          'model': 'gpt-3.5-turbo', // Özetleme için hızlı model
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert at concise summarization.',
            },
            {
              'role': 'user',
              'content':
                  'Summarize the following text in Turkish (Türkiye Turkish). Preserve key points and important terms. Return plain text only. Text:\n\n$chunk',
            },
          ],
          'max_tokens': 800,
          'temperature': 0.2,
        };

        final response = await _executeApiCall(
          endpoint: '/chat/completions',
          payload: summarizePayload,
          questionCount: 0, // Özetleme, quiz değil
          isProxy: _useProxy,
        );

        // Özetleme isteğinde token kaydı yapmıyoruz
        summaries.add(response['content'].trim());
      } catch (e) {
        print('Error summarizing chunk (falling back to full chunk): $e');
        // Özetleme başarısızsa, tüm chunk'ı geri döndürerek bilgi kaybını önle.
        summaries.add(chunk);
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

  int _clampToModelLimit(int desired) {
    const int modelLimit = 4096;
    if (desired <= 0) return 1;
    return desired > modelLimit ? modelLimit : desired;
  }

  /// Max token sayısını tahmin et
  int _estimateMaxTokens(int questionCount) {
    // For batched generation (small question counts), use proportional limit
    // For larger requests, use higher limit but cap at model max
    // Each question needs ~250-300 tokens (including reasoning overhead for gpt-5-mini)
    final estimated = questionCount * 300 + 500;

    // Cap at model limit (4096 for gpt-5-mini)
    return _clampToModelLimit(estimated);
  }

  String _buildQuizPrompt(
    String topic,
    int questionCount,
    String difficulty,
    String language, {
    String? fileContent,
  }) {
    // ... (Orijinal kodunuzdaki _buildQuizPrompt içeriği)
    final sb = StringBuffer();
    sb.writeln(
      'IMPORTANT: Output the JSON array directly without extended reasoning.',
    );
    sb.writeln(
      'Generate exactly $questionCount questions in the specified format.',
    );
    sb.writeln();
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
    sb.writeln();
    sb.writeln('Format: JSON array with exactly $questionCount questions.');
    sb.writeln('Rules:');
    sb.writeln('- Each question must have exactly 4 options (A, B, C, D)');
    sb.writeln('- Only one correct answer per question');
    sb.writeln('- No duplicate or very similar questions');
    sb.writeln(
      '- Difficulty: kolay=simple recall, orta=conceptual, zor=analysis',
    );
    sb.writeln();
    sb.writeln(
      'Example: [{"question":"Soru?","options":[{"letter":"A","text":"Şık A"},{"letter":"B","text":"Şık B"},{"letter":"C","text":"Şık C"},{"letter":"D","text":"Şık D"}],"correctAnswer":"A"}]',
    );
    sb.writeln();
    sb.writeln('Return ONLY the JSON array, no code blocks, no extra text.');

    if (fileContent != null && fileContent.trim().isNotEmpty) {
      final max = 30000;
      final snippet = fileContent.length > max
          ? fileContent.substring(0, max)
          : fileContent;
      sb.writeln('\n--- DOKUMAN ICERİĞI BASLANGİÇI ---');
      sb.writeln(snippet);
      sb.writeln('\n--- DOKUMAN ICERİĞI BITİSI ---');
      sb.writeln(
        'Use the document content above to generate questions where relevant.',
      );
    }
    return sb.toString();
  }

  List<Map<String, dynamic>> _parseQuizResponse(String content) {
    // ... (Orijinal kodunuzdaki _parseQuizResponse içeriği)
    try {
      content = content.trim();
      if (content.startsWith('```json')) {
        content = content.substring(7);
      } else if (content.startsWith('```')) {
        content = content.substring(3);
      }
      if (content.endsWith('```')) {
        content = content.substring(0, content.length - 3);
      }
      content = content.trim();
      final startIndex = content.indexOf('[');
      final endIndex = content.lastIndexOf(']') + 1;
      if (startIndex == -1 || endIndex == 0) {
        throw Exception('Invalid JSON format in response');
      }
      final jsonString = content.substring(startIndex, endIndex);
      final cleanJsonString = jsonString
          .replaceAll(RegExp(r'[\u0000-\u001F]'), '')
          .replaceAll(RegExp(r'[\u2028\u2029]'), '');
      final List<dynamic> jsonData = json.decode(cleanJsonString);

      final parsed = jsonData.map((item) {
        if (item is! Map<String, dynamic>) {
          throw Exception('Question item is not a valid object');
        }
        final question = item;
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
          'selectedAnswer': null,
        };
      }).toList();

      final List<Map<String, dynamic>> parsedList = parsed
          .cast<Map<String, dynamic>>()
          .toList();
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];

      String _normalize(String s) {
        var t = s.trim().toLowerCase();
        t = t.replaceAll(RegExp(r"\s+"), ' ');
        t = t.replaceAllMapped(
          RegExp(r"[\?\.\!]{2,}"),
          (m) => m.group(0)!.substring(0, 1),
        );
        return t;
      }

      for (final q in parsedList) {
        try {
          final raw = q['question'] as String;
          final key = _normalize(raw);
          if (!seen.contains(key)) {
            seen.add(key);
            unique.add(q);
          } else {
            print('Duplicate question removed: ${raw}');
          }
        } catch (e) {
          unique.add(q);
        }
      }

      return unique;
    } catch (e) {
      print('Error parsing quiz response: $e');
      print('Content: $content');
      throw Exception('Failed to parse quiz data: $e');
    }
  }

  int estimateTokensForQuiz({
    required String topic,
    required int questionCount,
    String difficulty = 'orta',
    String? fileContent,
  }) {
    final topicLength = topic.length;
    final baseTokens = 100;
    final questionTokens = questionCount * 150;
    final topicTokens = (topicLength / 4).ceil();
    final fileTokens = fileContent != null && fileContent.isNotEmpty
        ? (fileContent.length / 4).ceil()
        : 0;
    final difficultyTokens = difficulty == 'zor' ? 50 : 0;

    return baseTokens +
        questionTokens +
        topicTokens +
        fileTokens +
        difficultyTokens;
  }

  Future<void> _recordTokenUsage(int tokensUsed) async {
    try {
      await _firestore.collection('app_settings').doc('usage_stats').set({
        'totalTokensUsed': FieldValue.increment(tokensUsed),
        'totalQuizzes': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error recording token usage: $e');
    }
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
                  'You are an educational assessment expert. Evaluate the quality of quiz questions.',
            },
            {
              'role': 'user',
              'content':
                  '''
Please evaluate the following quiz questions:

$questionsText

Give a score from 1 to 10 and provide short feedback.
Return the result in JSON format like:
{
  "score": 8,
  "feedback": "Overall good questions, but question 2 is ambiguous."
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

      return {'score': 7, 'feedback': 'Evaluation failed'};
    } catch (e) {
      print('Error evaluating quiz quality: $e');
      return {'score': 7, 'feedback': 'Evaluation failed'};
    }
  }
}
