import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/screens/quiz_result.dart';
import '../providers/quiz_provider.dart';

class QuizPlayScreen extends StatelessWidget {
  const QuizPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.currentQuestion == null) {
            return const Center(
              child: Text(
                'Şu anda gösterilecek bir soru yok.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          final question = quizProvider.currentQuestion!;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Progress bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: quizProvider.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Soru
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isCorrect
                                    ? CupertinoColors.systemGreen.withOpacity(
                                        0.1,
                                      )
                                    : CupertinoColors.systemRed.withOpacity(
                                        0.1,
                                      ))
                              : CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (isCorrect
                                      ? CupertinoColors.systemGreen
                                      : CupertinoColors.systemRed)
                                : CupertinoColors.systemGrey4,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(16),
                          onPressed: () {
                            if (question.selectedAnswer == null) {
                              quizProvider.selectAnswer(option.letter);
                            }
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isCorrect
                                            ? CupertinoColors.systemGreen
                                            : CupertinoColors.systemRed)
                                      : CupertinoColors.activeBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    option.letter,
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option.text,
                                  style: const TextStyle(
                                    color: CupertinoColors.label,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  isCorrect
                                      ? CupertinoIcons.check_mark
                                      : CupertinoIcons.xmark,
                                  color: isCorrect
                                      ? CupertinoColors.systemGreen
                                      : CupertinoColors.systemRed,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Navigation butonları
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        onPressed: quizProvider.isFirstQuestion
                            ? null
                            : () => quizProvider.previousQuestion(),
                        color: CupertinoColors.systemGrey,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              CupertinoIcons.back,
                              color: CupertinoColors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Geri',
                              style: TextStyle(color: CupertinoColors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CupertinoButton(
                        onPressed: question.selectedAnswer == null
                            ? null
                            : () {
                                if (quizProvider.isLastQuestion) {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          const QuizResultScreen(),
                                    ),
                                  );
                                } else {
                                  quizProvider.nextQuestion();
                                }
                              },
                        color: CupertinoColors.activeBlue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              quizProvider.isLastQuestion
                                  ? CupertinoIcons.flag
                                  : CupertinoIcons.forward,
                              color: CupertinoColors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              quizProvider.isLastQuestion ? 'Bitir' : 'İleri',
                              style: const TextStyle(
                                color: CupertinoColors.white,
                              ),
                            ),
                          ],
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
