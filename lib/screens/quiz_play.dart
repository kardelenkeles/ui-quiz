import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/screens/quiz_result.dart';
import '../providers/quiz_provider.dart';

class QuizPlayScreen extends StatelessWidget {
  const QuizPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: Colors.blueAccent,
        actions: [
          Consumer<QuizProvider>(
            builder: (context, quizProvider, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${quizProvider.currentQuestionIndex + 1}/${quizProvider.totalQuestions}',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.currentQuestion == null) {
            return const Center(child: Text('Quiz yükleniyor...'));
          }

          final question = quizProvider.currentQuestion!;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: quizProvider.progress,
                  backgroundColor: Colors.grey[300],
                  color: Colors.blueAccent,
                ),

                const SizedBox(height: 20),

                // Soru
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          question.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Soru ${quizProvider.currentQuestionIndex + 1} / ${quizProvider.totalQuestions}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Seçenekler
                Expanded(
                  child: ListView.builder(
                    itemCount: question.options.length,
                    itemBuilder: (context, index) {
                      final option = question.options[index];
                      final isSelected =
                          question.selectedAnswer == option.letter;
                      final isCorrect = question.correctAnswer == option.letter;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: isSelected
                            ? (isCorrect ? Colors.green[100] : Colors.red[100])
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? (isCorrect ? Colors.green : Colors.red)
                                : Colors.blueAccent,
                            child: Text(
                              option.letter,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(option.text),
                          onTap: () {
                            if (question.selectedAnswer == null) {
                              quizProvider.selectAnswer(option.letter);
                            }
                          },
                          trailing: isSelected
                              ? Icon(
                                  isCorrect ? Icons.check : Icons.close,
                                  color: isCorrect ? Colors.green : Colors.red,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),

                // Navigation butonları
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: quizProvider.isFirstQuestion
                            ? null
                            : () => quizProvider.previousQuestion(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Geri'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: question.selectedAnswer == null
                            ? null
                            : () {
                                if (quizProvider.isLastQuestion) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const QuizResultScreen(),
                                    ),
                                  );
                                } else {
                                  quizProvider.nextQuestion();
                                }
                              },
                        icon: Icon(
                          quizProvider.isLastQuestion
                              ? Icons.flag
                              : Icons.arrow_forward,
                        ),
                        label: Text(
                          quizProvider.isLastQuestion ? 'Bitir' : 'İleri',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
