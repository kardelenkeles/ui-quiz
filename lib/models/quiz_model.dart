class Quiz {
  final String language;
  final List<Question> questions;
  final int questionCount;
  final int totalQuestions;

  Quiz({
    required this.language,
    required this.questions,
    required this.questionCount,
    required this.totalQuestions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    var questionsList = json['questions'] as List;
    List<Question> questions = questionsList
        .map((i) => Question.fromJson(i))
        .toList();

    return Quiz(
      language: json['language'] ?? 'en',
      questions: questions,
      questionCount: json['question_count'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
    );
  }
}

class Question {
  final String question;
  final List<Option> options;
  final String correctAnswer;
  final String explanation;
  String? selectedAnswer;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.selectedAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var optionsList = json['options'] as List;
    List<Option> options = optionsList.map((i) => Option.fromJson(i)).toList();

    return Question(
      question: json['question'] ?? '',
      options: options,
      correctAnswer: json['correct_answer'] ?? 'A',
      explanation: json['explanation'] ?? '',
    );
  }

  bool get isCorrect => selectedAnswer == correctAnswer;
}

class Option {
  final String letter;
  final String text;

  Option({required this.letter, required this.text});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(letter: json['letter'] ?? 'A', text: json['text'] ?? '');
  }
}

class ApiResponse {
  final bool success;
  final Quiz? quiz;
  final String? error;
  final Map<String, dynamic>? metadata;

  ApiResponse({required this.success, this.quiz, this.error, this.metadata});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      quiz: json['quiz'] != null ? Quiz.fromJson(json['quiz']) : null,
      error: json['error'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}
