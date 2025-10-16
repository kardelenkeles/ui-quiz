import 'package:flutter/foundation.dart';
import 'package:ui_quiz/services/service_locator.dart';

class NewQuizProvider extends ChangeNotifier {
  // Loading states
  bool _isGenerating = false;
  bool _isLoading = false;

  // Quiz data
  List<Map<String, dynamic>> _currentQuestions = [];
  String _currentQuizId = '';
  String _currentQuizTitle = '';
  int _currentTokensUsed = 0;
  String _currentTopic = '';

  // Error handling
  String _error = '';

  // User quota info
  Map<String, dynamic> _quotaInfo = {};

  // Quiz history
  List<Map<String, dynamic>> _quizHistory = [];
  Map<String, dynamic> _userStats = {};

  // Getters
  bool get isGenerating => _isGenerating;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get currentQuestions => _currentQuestions;
  String get currentQuizId => _currentQuizId;
  String get currentQuizTitle => _currentQuizTitle;
  String get error => _error;
  Map<String, dynamic> get quotaInfo => _quotaInfo;
  List<Map<String, dynamic>> get quizHistory => _quizHistory;
  Map<String, dynamic> get userStats => _userStats;

  /// Quiz oluştur
  Future<bool> generateQuiz({
    required String topic,
    required int questionCount,
    String difficulty = 'orta',
    String? fileContent,
    String? originalFileName,
  }) async {
    _isGenerating = true;
    _error = '';
    notifyListeners();

    try {
      // Quota kontrolü
      final canCreate = await services.quotaService.canCreateQuiz();
      if (!canCreate) {
        _error =
            'Günlük quiz limitiniz doldu. Premium hesaba geçerek sınırsız quiz oluşturabilirsiniz.';
        return false;
      }

      // Quiz oluştur - enforce requested questionCount in the provider rather than relying
      // solely on the model prompt. We'll request in batches and deduplicate across
      // responses. Make up to 3 attempts to reach the requested unique question count.

      // Map difficulty keys from UI to service-expected values (use Turkish keys)
      String _mapDifficulty(String d) {
        final lower = d.trim().toLowerCase();
        if (lower == 'easy' || lower == 'kolay') return 'kolay';
        if (lower == 'mid' || lower == 'orta' || lower == 'medium')
          return 'orta';
        if (lower == 'hard' || lower == 'zor') return 'zor';
        return d; // fallback: pass through
      }

      final mappedDifficulty = _mapDifficulty(difficulty);

      // Helper to normalize question text for duplicate detection
      String _normalize(String s) {
        var t = s.trim().toLowerCase();
        t = t.replaceAll(RegExp(r"\s+"), ' ');
        t = t.replaceAllMapped(
          RegExp(r"[\?\.\!]{2,}"),
          (m) => m.group(0)!.substring(0, 1),
        );
        return t;
      }

      final accumulated = <Map<String, dynamic>>[];
      final seen = <String>{};

      int attempts = 0;
      const int maxAttempts = 3;

      while (accumulated.length < questionCount && attempts < maxAttempts) {
        attempts++;
        final remaining = questionCount - accumulated.length;

        // Request the remaining number of questions. The service may still return
        // duplicates; we'll deduplicate here and try again if needed.
        final batch = await services.openAIService.generateQuiz(
          topic: topic,
          questionCount: remaining,
          difficulty: mappedDifficulty,
          fileContent: fileContent,
        );

        for (final q in batch) {
          try {
            final qText = q['question'] as String;
            final key = _normalize(qText);
            if (!seen.contains(key)) {
              seen.add(key);
              accumulated.add(q);
            } else {
              // duplicate within or across batches; skip
            }
          } catch (e) {
            // If structure unexpected, try to add it to avoid losing content
            accumulated.add(q);
          }
        }

        // If after this attempt we still have fewer than requested, loop and try again
      }

      // If we have more than requested (shouldn't normally happen), trim
      final questions = accumulated.length > questionCount
          ? accumulated.sublist(0, questionCount)
          : accumulated;

      if (questions.isEmpty) {
        _error = 'Quiz could not be generated. Try changing the topic.';
        return false;
      }

      if (questions.length < questionCount) {
        // Not enough unique questions after attempts; set an informative error but still
        // proceed with what we have (or you could choose to treat as failure). Here we
        // proceed but inform the user.
        _error =
            'Only ${questions.length} unique questions could be generated (requested $questionCount).';
      }

      // Determine quiz title: prefer original filename (without extension), else topic-based title
      String quizTitle;
      if (originalFileName != null && originalFileName.trim().isNotEmpty) {
        // remove extension if present
        quizTitle = originalFileName.replaceAll(RegExp(r"\.[^\.]+$"), '');
      } else {
        quizTitle = '$topic Quiz';
      }
      final tokensUsed = services.openAIService.estimateTokensForQuiz(
        topic: topic,
        questionCount: questionCount,
        difficulty: mappedDifficulty,
      );

      // Quiz'i henüz Firebase'e kaydetme, sadece memory'de tut
      // Quiz tamamlandığında kaydedilecek

      // Quota kullanımını artır
      await services.quotaService.incrementUsage(tokensUsed: tokensUsed);

      // State'i güncelle
      _currentQuestions = questions;
      _currentQuizId = ''; // Henüz kaydedilmediği için boş
      _currentQuizTitle = quizTitle;

      // Geçici olarak token ve topic bilgilerini sakla
      _currentTokensUsed = tokensUsed;
      _currentTopic = topic;

      // Quota bilgisini güncelle
      await _updateQuotaInfo();

      return true;
    } catch (e) {
      _error = 'Quiz oluşturulurken hata oluştu: $e';
      print('Error generating quiz: $e');
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Quiz cevabını güncelle
  void updateAnswer(int questionIndex, String selectedAnswer) {
    if (questionIndex >= 0 && questionIndex < _currentQuestions.length) {
      _currentQuestions[questionIndex]['selectedAnswer'] = selectedAnswer;
      notifyListeners();
    }
  }

  /// Quiz'i tamamla ve sonucu kaydet
  Future<Map<String, dynamic>> completeQuiz() async {
    try {
      // Score hesapla
      int correctAnswers = 0;
      for (final question in _currentQuestions) {
        if (question['selectedAnswer'] == question['correctAnswer']) {
          correctAnswers++;
        }
      }

      final totalQuestions = _currentQuestions.length;
      final scorePercentage = ((correctAnswers / totalQuestions) * 100).round();

      // Şimdi quiz'i Firebase'e kaydet (ilk defa)
      final quizId = await services.quizStorageService.saveQuiz(
        title: _currentQuizTitle,
        questions: _currentQuestions,
        tokensUsed: _currentTokensUsed,
      );

      // Quiz ID'sini güncelle
      _currentQuizId = quizId;

      // Sonucu güncelle
      await services.quizStorageService.updateQuizResult(
        quizId: quizId,
        score: scorePercentage,
        questionsWithAnswers: _currentQuestions,
      );

      // Konu popülerliğini güncelle (quiz tamamlandığında)
      if (_currentTopic.isNotEmpty) {
        await services.quizStorageService.updateTopicPopularity(_currentTopic);
      }

      // Quiz geçmişini güncelle
      await loadQuizHistory();

      return {
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'scorePercentage': scorePercentage,
        'questions': _currentQuestions,
      };
    } catch (e) {
      _error = 'Quiz sonucu kaydedilirken hata oluştu: $e';
      print('Error completing quiz: $e');
      rethrow;
    }
  }

  /// Quiz geçmişini yükle
  Future<void> loadQuizHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _quizHistory = await services.quizStorageService.getUserQuizHistory();
      _userStats = await services.quizStorageService.getUserStats();
    } catch (e) {
      _error = 'Quiz geçmişi yüklenirken hata oluştu: $e';
      print('Error loading quiz history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Quota bilgisini güncelle
  Future<void> _updateQuotaInfo() async {
    try {
      _quotaInfo = await services.quotaService.getRemainingQuota();
    } catch (e) {
      print('Error updating quota info: $e');
    }
  }

  /// Quota bilgisini al (public metod)
  Future<void> updateQuotaInfo() async {
    await _updateQuotaInfo();
    notifyListeners();
  }

  /// Quiz'i sil
  Future<bool> deleteQuiz(String quizId) async {
    try {
      await services.quizStorageService.deleteQuiz(quizId);

      // Local listeden kaldır
      _quizHistory.removeWhere((quiz) => quiz['id'] == quizId);

      // Stats'i güncelle
      _userStats = await services.quizStorageService.getUserStats();

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Quiz silinirken hata oluştu: $e';
      print('Error deleting quiz: $e');
      return false;
    }
  }

  /// Quiz ara
  Future<List<Map<String, dynamic>>> searchQuizzes(String searchTerm) async {
    try {
      return await services.quizStorageService.searchQuizzes(
        searchTerm: searchTerm,
      );
    } catch (e) {
      _error = 'Quiz arama sırasında hata oluştu: $e';
      print('Error searching quizzes: $e');
      return [];
    }
  }

  /// Popüler konuları al
  Future<List<Map<String, dynamic>>> getPopularTopics() async {
    try {
      return await services.quizStorageService.getPopularTopics();
    } catch (e) {
      print('Error getting popular topics: $e');
      return [];
    }
  }

  /// Quiz yükle (ID ile)
  Future<bool> loadQuizById(String quizId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final quiz = await services.quizStorageService.getQuizById(quizId);

      if (quiz == null) {
        _error = 'Quiz bulunamadı';
        return false;
      }

      _currentQuizId = quiz['id'];
      _currentQuizTitle = quiz['title'];
      _currentQuestions = List<Map<String, dynamic>>.from(quiz['questions']);

      return true;
    } catch (e) {
      _error = 'Quiz yüklenirken hata oluştu: $e';
      print('Error loading quiz by ID: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mevcut quiz'i temizle
  void clearCurrentQuiz() {
    _currentQuestions.clear();
    _currentQuizId = '';
    _currentQuizTitle = '';
    _currentTokensUsed = 0;
    _currentTopic = '';
    _error = '';
    notifyListeners();
  }

  /// Hata mesajını temizle
  void clearError() {
    _error = '';
    notifyListeners();
  }

  /// Premium durum kontrolü
  Future<bool> isPremiumUser() async {
    try {
      return await services.quotaService.isPremiumUser();
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  /// Quiz kalitesini değerlendir (premium özellik)
  Future<Map<String, dynamic>?> evaluateQuizQuality() async {
    if (_currentQuestions.isEmpty) return null;

    try {
      return await services.openAIService.evaluateQuizQuality(
        _currentQuestions,
      );
    } catch (e) {
      print('Error evaluating quiz quality: $e');
      return null;
    }
  }

  /// Sistem sağlık kontrolü
  Future<Map<String, bool>> performHealthCheck() async {
    try {
      return await services.healthCheck();
    } catch (e) {
      print('Error performing health check: $e');
      return {};
    }
  }

  /// Quiz sonucunu kaydet (QuizResultScreen için)
  Future<void> saveQuizResult({
    required String quizTitle,
    required List<Map<String, dynamic>> questions,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Quiz'i kaydet
      final quizId = await services.quizStorageService.saveQuiz(
        title: quizTitle,
        questions: questions,
      );

      final scorePercentage = ((correctAnswers / totalQuestions) * 100).round();

      // Sonucu güncelle
      await services.quizStorageService.updateQuizResult(
        quizId: quizId,
        score: scorePercentage,
        questionsWithAnswers: questions,
      );

      // Quiz geçmişini güncelle
      await loadQuizHistory();

      _isLoading = false;
      notifyListeners();

      print('Quiz result saved with ID: $quizId');
    } catch (e) {
      _error = 'Quiz sonucu kaydedilirken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      print('Error saving quiz result: $e');
      rethrow;
    }
  }
}
