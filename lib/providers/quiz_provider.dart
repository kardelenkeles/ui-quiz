import 'package:flutter/foundation.dart';
import '../models/quiz_model.dart';
import '../services/api_service.dart';

class QuizProvider with ChangeNotifier {
  bool _isLoading = false;
  String _error = '';
  Quiz? _currentQuiz;
  int _currentQuestionIndex = 0;
  int _score = 0;

  bool get isLoading => _isLoading;
  String get error => _error;
  Quiz? get currentQuiz => _currentQuiz;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get totalQuestions => _currentQuiz?.questions.length ?? 0;
  Question? get currentQuestion =>
      _currentQuiz != null && _currentQuiz!.questions.isNotEmpty
      ? _currentQuiz!.questions[_currentQuestionIndex]
      : null;

  Future<void> generateQuiz(String text, {String language = 'auto'}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    final response = await ApiService.generateQuiz(text, language: language);

    _isLoading = false;

    if (response['success'] == true && response['quiz'] != null) {
      _currentQuiz = response['quiz'];
      _currentQuestionIndex = 0;
      _score = 0;
      _error = '';
    } else {
      _error = response['error'] ?? 'Unknown error occurred';
      _currentQuiz = null;
    }

    notifyListeners();
  }

  void selectAnswer(String answer) {
    if (currentQuestion != null) {
      _currentQuiz!.questions[_currentQuestionIndex].selectedAnswer = answer;

      if (answer == currentQuestion!.correctAnswer) {
        _score++;
      }

      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < totalQuestions - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void resetQuiz() {
    _currentQuiz = null;
    _currentQuestionIndex = 0;
    _score = 0;
    _error = '';
    notifyListeners();
  }

  bool get isLastQuestion => _currentQuestionIndex == totalQuestions - 1;
  bool get isFirstQuestion => _currentQuestionIndex == 0;
  double get progress =>
      totalQuestions > 0 ? (_currentQuestionIndex + 1) / totalQuestions : 0;
}
