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
        // Çok uzun dosyalar için progressif özetleme
        const int veryLongThreshold = 50000; // 50K karakterden uzun
        const int longThreshold = 15000; // 15K karakterden uzun

        if (fileContent.length > veryLongThreshold) {
          // Çok uzun dosyalar: önce parçalara böl, her parçayı özetle, sonra birleştir
          final summary = await _summarizeLargeText(fileContent);
          promptFileContent = summary;
        } else if (fileContent.length > longThreshold) {
          // Orta uzunlukta dosyalar: tek seferde özetle
          final summary = await _summarizeText(fileContent);
          promptFileContent = summary;
        }
        // Kısa dosyalar için direkt kullan
      }

      // Dosya içeriğinden dil tespiti yap
      final detectedLanguage =
          promptFileContent != null && promptFileContent.isNotEmpty
          ? _detectLanguage(promptFileContent)
          : language;

      final prompt = _buildQuizPrompt(
        topic,
        questionCount,
        difficulty,
        detectedLanguage,
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

      // Vision için gpt-4o-mini, Metin için gpt-5-mini
      final model = isImageFile ? 'gpt-4o-mini' : 'gpt-5-mini';

      final Map<String, dynamic> bodyPayload;

      final int estimatedMaxTokens = _estimateMaxTokens(questionCount);

      if (isImageFile && imageBase64 != null) {
        bodyPayload = {
          'model': model, // gpt-4o-mini
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert quiz creator. You MUST generate educational, high-quality multiple-choice questions based on the provided image and instructions. You MUST output ONLY a valid JSON array of questions. DO NOT ask questions back to the user. DO NOT explain anything. ONLY return the JSON array.',
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
          'temperature': 0.7,
        };
      } else {
        bodyPayload = {
          'model': model, // gpt-5-mini
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert quiz creator. You MUST generate educational, high-quality multiple-choice questions based on the provided content. You MUST output ONLY a valid JSON array of questions. DO NOT ask questions back to the user. DO NOT explain anything. DO NOT say you need more information. Use the provided content to create questions. ONLY return the JSON array.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_completion_tokens': estimatedMaxTokens,
          // Note: gpt-5-mini only supports temperature=1 (default), so we omit it
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
          throw Exception('Please sign in first.');
        }
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        };

        // Try sending a gzipped request body to reduce upload size.
        try {
          final jsonBody = json.encode(currentPayload);
          final bodyBytes = utf8.encode(jsonBody);
          final gzipped = gzip.encode(bodyBytes);
          // Indicate compressed payload to server
          headers['Content-Encoding'] = 'gzip';
          return http.post(
            Uri.parse('$_backendProxyBase/openai/chat'),
            headers: headers,
            body: gzipped,
          );
        } catch (e) {
          // Fallback to plain JSON if gzip fails for any reason
          return http.post(
            Uri.parse('$_backendProxyBase/openai/chat'),
            headers: headers,
            body: json.encode(currentPayload),
          );
        }
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

      // Increase by 50% or at least 1000 tokens to ensure completion
      final increased = _clampToModelLimit(
        ((origMax * 1.5).toInt().clamp(origMax + 1000, 4096)),
      );

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
                  'You MUST output ONLY a valid JSON array of quiz questions. DO NOT ask questions. DO NOT explain. ONLY return JSON.',
            },
            {
              'role': 'user',
              'content':
                  'URGENT: Your previous response was empty. You MUST now output a JSON array of $questionCount quiz questions. DO NOT ask what topic I want. DO NOT explain anything. Just output the JSON array starting with [ and ending with ]. Format: [{"question":"...","options":[{"letter":"A","text":"..."},{"letter":"B","text":"..."},{"letter":"C","text":"..."},{"letter":"D","text":"..."}],"correctAnswer":"A"}]. Start NOW with [:',
            },
          ],
          'max_completion_tokens': _clampToModelLimit(
            _estimateMaxTokens(questionCount),
          ),
          // Note: gpt-5-mini only supports temperature=1 (default), so we omit it
        };

        try {
          response = await _makeRequest(rescuePayload);
          parsed = _parseResponse(response);
          totalTokensUsed += parsed['tokensUsed'] as int;
          content = parsed['content'] as String?;
        } catch (e) {
          print('Rescue request failed: $e');
          throw Exception(
            'API could not generate quiz. Please try again with a more specific topic or different content.',
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

  /// Metinden dili otomatik tespit et
  String _detectLanguage(String text) {
    if (text.isEmpty) return 'English';

    final sample = text.substring(0, text.length.clamp(0, 1000)).toLowerCase();

    // Türkçe karakterler ve yaygın kelimeler
    final turkishChars = RegExp(r'[çğıöşü]');
    final turkishWords = [
      'bir',
      'bu',
      've',
      'için',
      'olan',
      'ile',
      'den',
      'dan',
      'da',
      'de',
      'ama',
      'veya',
      'gibi',
    ];

    // İngilizce yaygın kelimeler
    final englishWords = [
      'the',
      'is',
      'are',
      'was',
      'were',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
    ];

    int turkishScore = 0;
    int englishScore = 0;

    if (turkishChars.hasMatch(sample)) turkishScore += 10;

    for (final word in turkishWords) {
      if (RegExp(r'\b' + word + r'\b').hasMatch(sample)) turkishScore += 2;
    }

    for (final word in englishWords) {
      if (RegExp(r'\b' + word + r'\b').hasMatch(sample)) englishScore += 1;
    }

    return turkishScore > englishScore ? 'Turkish' : 'English';
  }

  /// Çok büyük dosyalar için progressif özetleme
  Future<String> _summarizeLargeText(String text) async {
    // İlk aşama: metni büyük parçalara böl ve her birini özetle
    final largeChunks = _chunkText(text, 8000);
    final firstPassSummaries = <String>[];

    for (final chunk in largeChunks) {
      try {
        final summary = await _summarizeText(chunk);
        firstPassSummaries.add(summary);
      } catch (e) {
        print('Error summarizing large chunk: $e');
        // Hata durumunda chunk'ın ilk kısmını al
        firstPassSummaries.add(chunk.substring(0, chunk.length.clamp(0, 2000)));
      }
    }

    // İkinci aşama: özetleri birleştir ve tekrar özetle
    final combinedSummary = firstPassSummaries.join('\n\n');
    if (combinedSummary.length > 10000) {
      return await _summarizeText(combinedSummary);
    }
    return combinedSummary;
  }

  /// Basit chunk + summarize akışı. Uzun metinler için özet döner.
  Future<String> _summarizeText(String text) async {
    // Metni daha küçük parçalara böl (token limitleri için)
    final chunks = _chunkText(text, 4000);
    final summaries = <String>[];

    for (final chunk in chunks) {
      try {
        final summarizePayload = {
          'model': 'gpt-3.5-turbo', // Özetleme için hızlı model
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert at concise summarization. You MUST preserve the EXACT original language of the text. NEVER translate. If input is Turkish, output must be Turkish. If input is English, output must be English.',
            },
            {
              'role': 'user',
              'content':
                  'CRITICAL: Summarize this text in the EXACT SAME LANGUAGE as the input. DO NOT translate to English or any other language. If the text is in Turkish, your summary MUST be in Turkish. If it is in English, your summary MUST be in English. Keep ALL key facts, important terms, definitions, and main concepts. Be comprehensive but concise. Return plain text only.\n\nText:\n$chunk',
            },
          ],
          'max_tokens': 1500,
          'temperature': 0.3,
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
    if (text.isEmpty) return [];
    if (size <= 0) size = 1000; // Default safe size

    final parts = <String>[];
    int index = 0;
    while (index < text.length) {
      final end = (index + size).clamp(0, text.length);
      if (index >= end) break; // Safety check
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
    // Each question needs ~400-500 tokens (Turkish and complex questions need more space)
    // Base tokens for formatting and structure
    final estimated = questionCount * 500 + 800;

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
    final sb = StringBuffer();

    // Strict JSON-only instruction
    sb.writeln(
      'CRITICAL INSTRUCTION: You MUST output ONLY a valid JSON array.',
    );
    sb.writeln('DO NOT ask for clarification. DO NOT explain anything.');
    sb.writeln('DO NOT include any text before or after the JSON array.');
    sb.writeln('Generate EXACTLY $questionCount multiple-choice questions.');
    sb.writeln();

    if (fileContent != null && fileContent.trim().isNotEmpty) {
      sb.writeln(
        'Based on the document content provided below, create $questionCount multiple-choice questions in $language.',
      );
      sb.writeln('Difficulty level: $difficulty');
      sb.writeln();
      sb.writeln(
        'Analyze the document and create questions that test understanding of its key concepts.',
      );
    } else if (topic.trim().isNotEmpty) {
      sb.writeln(
        'Create $questionCount multiple-choice questions about "$topic" in $language.',
      );
      sb.writeln('Difficulty level: $difficulty');
      sb.writeln();
    } else {
      sb.writeln(
        'Create $questionCount general knowledge multiple-choice questions in $language.',
      );
      sb.writeln('Difficulty level: $difficulty');
      sb.writeln();
    }

    sb.writeln('JSON FORMAT REQUIREMENTS:');
    sb.writeln(
      '- Each question MUST have exactly 4 options labeled A, B, C, D',
    );
    sb.writeln('- Only one correct answer per question');
    sb.writeln('- No duplicate or similar questions');
    sb.writeln(
      '- Difficulty levels: kolay=basic recall, orta=conceptual understanding, zor=critical analysis',
    );
    sb.writeln();
    sb.writeln('EXACT JSON STRUCTURE:');
    sb.writeln('[');
    sb.writeln('  {');
    sb.writeln('    "question": "Question text here?",');
    sb.writeln('    "options": [');
    sb.writeln('      {"letter": "A", "text": "First option"},');
    sb.writeln('      {"letter": "B", "text": "Second option"},');
    sb.writeln('      {"letter": "C", "text": "Third option"},');
    sb.writeln('      {"letter": "D", "text": "Fourth option"}');
    sb.writeln('    ],');
    sb.writeln('    "correctAnswer": "A"');
    sb.writeln('  }');
    sb.writeln(']');
    sb.writeln();
    sb.writeln(
      'REMINDER: Output ONLY the JSON array. No code blocks (```), no explanations, no questions back to me.',
    );

    if (fileContent != null && fileContent.trim().isNotEmpty) {
      final max = 50000; // Increased from 30K to 50K for larger files
      final snippet = fileContent.length > max
          ? fileContent.substring(0, max.clamp(0, fileContent.length))
          : fileContent;
      sb.writeln();
      sb.writeln('=== DOCUMENT CONTENT START ===');
      sb.writeln(snippet);
      sb.writeln('=== DOCUMENT CONTENT END ===');
      sb.writeln();
      sb.writeln(
        'Generate questions based on the document content above. Start your response with [',
      );
    } else {
      sb.writeln();
      sb.writeln('Start your response with [ (opening bracket of JSON array).');
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

      final parsed = <Map<String, dynamic>>[];

      for (final item in jsonData) {
        try {
          if (item is! Map<String, dynamic>) {
            print('Skipping invalid question item (not an object)');
            continue;
          }
          final question = item;
          if (!question.containsKey('question') ||
              !question.containsKey('options') ||
              !question.containsKey('correctAnswer')) {
            print('Skipping question with missing fields: ${question.keys}');
            continue;
          }
          if (!(question['options'] is List)) {
            print('Skipping question with invalid options array');
            continue;
          }
          final options = question['options'] as List<dynamic>;
          if (options.isEmpty || options.length != 4) {
            print(
              'Skipping question with ${options.length} options (expected 4): ${question['question']}',
            );
            continue;
          }

          // Validate all options have letter and text
          bool allOptionsValid = true;
          for (final option in options) {
            if (!(option is Map<String, dynamic>)) {
              allOptionsValid = false;
              break;
            }
            final opt = option;
            if (!opt.containsKey('letter') || !opt.containsKey('text')) {
              allOptionsValid = false;
              break;
            }
            if (!(opt['letter'] is String) || !(opt['text'] is String)) {
              allOptionsValid = false;
              break;
            }
          }

          if (!allOptionsValid) {
            print(
              'Skipping question with malformed options: ${question['question']}',
            );
            continue;
          }

          // Valid question, add to parsed list
          parsed.add({
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
          });
        } catch (e) {
          print('Error parsing individual question: $e');
          continue;
        }
      }

      final List<Map<String, dynamic>> parsedList = parsed;
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
