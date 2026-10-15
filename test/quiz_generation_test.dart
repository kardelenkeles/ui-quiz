import 'package:flutter_test/flutter_test.dart';
import 'package:ui_quiz/providers/new_quiz_provider.dart';
import 'package:ui_quiz/services/openai_service.dart';
import 'package:ui_quiz/services/quota_service.dart';

class _FakeQuizGenerator implements QuizGenerator {
  String? receivedDifficulty;

  @override
  Future<Map<String, dynamic>> generateQuiz({
    required String topic,
    required int questionCount,
    String difficulty = 'orta',
    String language = 'Turkish',
    String? fileContent,
    String? filePath,
    void Function(int currentBatch, int totalBatches)? onBatchProgress,
  }) async {
    receivedDifficulty = difficulty;
    return {
      'questions': <Map<String, dynamic>>[
        {'question': 'What is Flutter?', 'correctAnswer': 'A'},
        {'question': 'What is Dart?', 'correctAnswer': 'B'},
        {'question': 'what is flutter!', 'correctAnswer': 'A'},
      ],
      'tokensUsed': 42,
    };
  }
}

class _FakeQuotaReader implements QuotaReader {
  @override
  Future<Map<String, dynamic>> getRemainingQuota() async => {
    'plan': 'free',
    'dailyRemaining': 29,
  };
}

void main() {
  test(
    'quiz generation maps difficulty and removes duplicate questions',
    () async {
      final generator = _FakeQuizGenerator();
      final provider = NewQuizProvider(
        quizGenerator: generator,
        quotaReader: _FakeQuotaReader(),
      );

      final generated = await provider.generateQuiz(
        topic: 'Flutter',
        questionCount: 2,
        difficulty: 'hard',
        originalFileName: 'lesson.pdf',
      );

      expect(generated, isTrue);
      expect(generator.receivedDifficulty, 'zor');
      expect(provider.currentQuestions, hasLength(2));
      expect(provider.currentQuizTitle, 'lesson');
      expect(provider.quotaInfo['dailyRemaining'], 29);
      expect(provider.isGenerating, isFalse);
    },
  );
}
