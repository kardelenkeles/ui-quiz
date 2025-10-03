import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';
import 'package:ui_quiz/screens/quiz_play.dart';

class QuizResultScreen extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final List<Map<String, dynamic>> questions;

  const QuizResultScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final successRate = (correctAnswers / totalQuestions * 100);
    final isSuccess = successRate >= 70;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        leading: CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              CupertinoPageRoute(
                builder: (context) => const CustomTabBarWidget(initialIndex: 1),
              ),
            );
          },
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.systemBlue,
            size: 24,
          ),
        ),
        middle: const Text(
          'Quiz Sonucu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      child: Stack(
        children: [
          if (isSuccess)
            Positioned.fill(
              child: Lottie.asset(
                'asset/animations/Confetti.json',
                repeat: true,
                animate: true,
                fit: BoxFit.cover,
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Skor kartı - en üstte
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? CupertinoColors.systemGreen.withOpacity(0.1)
                          : CupertinoColors.systemOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSuccess
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemOrange,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSuccess
                                  ? 'Tebrikler! 🎉'
                                  : 'Daha İyi Olabilir! 💪',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.label,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$correctAnswers / $totalQuestions doğru',
                              style: TextStyle(
                                fontSize: 16,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSuccess
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${successRate.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cevaplar başlığı
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cevaplarının Detayı:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cevaplar listesi
                  Expanded(
                    child: ListView.builder(
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        final isCorrect =
                            question['selectedAnswer'] ==
                            question['correctAnswer'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCorrect
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemRed,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.systemGrey.withOpacity(
                                  0.1,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Soru başlığı
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isCorrect
                                          ? CupertinoColors.systemGreen
                                          : CupertinoColors.systemRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCorrect
                                          ? CupertinoIcons.check_mark
                                          : CupertinoIcons.xmark,
                                      color: CupertinoColors.white,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Soru ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Soru metni
                              Text(
                                question['question'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.secondaryLabel,
                                  height: 1.3,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Tüm şıklar
                              Text(
                                'Şıklar:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                              const SizedBox(height: 8),

                              ...((question['options'] as List).map<Widget>((
                                option,
                              ) {
                                final isSelectedOption =
                                    option['letter'] ==
                                    question['selectedAnswer'];
                                final isCorrectOption =
                                    option['letter'] ==
                                    question['correctAnswer'];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelectedOption
                                        ? (isCorrectOption
                                              ? CupertinoColors.systemGreen
                                                    .withOpacity(0.15)
                                              : CupertinoColors.systemRed
                                                    .withOpacity(0.15))
                                        : (isCorrectOption
                                              ? CupertinoColors.systemGreen
                                                    .withOpacity(0.1)
                                              : CupertinoColors.systemGrey6),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelectedOption
                                          ? (isCorrectOption
                                                ? CupertinoColors.systemGreen
                                                : CupertinoColors.systemRed)
                                          : (isCorrectOption
                                                ? CupertinoColors.systemGreen
                                                : CupertinoColors.systemGrey4),
                                      width: isSelectedOption || isCorrectOption
                                          ? 1.5
                                          : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        option['letter'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSelectedOption
                                              ? (isCorrectOption
                                                    ? CupertinoColors
                                                          .systemGreen
                                                    : CupertinoColors.systemRed)
                                              : (isCorrectOption
                                                    ? CupertinoColors
                                                          .systemGreen
                                                    : CupertinoColors.label),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          option['text'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: CupertinoColors.label,
                                          ),
                                        ),
                                      ),
                                      if (isSelectedOption || isCorrectOption)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: isCorrectOption
                                                ? CupertinoColors.systemGreen
                                                : CupertinoColors.systemRed,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCorrectOption
                                                ? CupertinoIcons.check_mark
                                                : (isSelectedOption
                                                      ? CupertinoIcons.xmark
                                                      : CupertinoIcons
                                                            .check_mark),
                                            color: CupertinoColors.white,
                                            size: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList()),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton.filled(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              CupertinoPageRoute(
                                builder: (context) => const QuizPlayScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: const Text(
                            'Tekrar Dene',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const CustomTabBarWidget(initialIndex: 1),
                              ),
                            );
                          },
                          color: CupertinoColors.systemGrey5,
                          borderRadius: BorderRadius.circular(16),
                          child: const Text(
                            'Ana Sayfaya Dön',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
