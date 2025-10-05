import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';
import 'package:ui_quiz/screens/quiz/quiz_play.dart';

class QuizResultScreen extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final List<Map<String, dynamic>> questions;
  final String? quizName;

  const QuizResultScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.questions,
    this.quizName,
  });

  @override
  Widget build(BuildContext context) {
    final successRate = (correctAnswers / totalQuestions * 100);
    final isSuccess = successRate >= 70;

    return CupertinoPageScaffold(
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
                  const SizedBox(height: 5),

                  // Quiz adı
                  if (quizName != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quizName!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.label,
                          decoration: TextDecoration.none,
                          fontFamily: 'Nunito',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Skor kartı
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(10),
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
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSuccess
                                    ? 'Tebrikler! 🎉'
                                    : 'Daha İyi Olabilir! 💪',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.label,
                                  decoration: TextDecoration.none,
                                  fontFamily: 'Nunito',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$correctAnswers / $totalQuestions doğru',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.secondaryLabel,
                                  decoration: TextDecoration.none,
                                  fontFamily: 'Nunito',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
                              decoration: TextDecoration.none,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.white,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cevaplar listesi
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      radius: const Radius.circular(8),
                      thickness: 2,
                      child: ListView.builder(
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          final isCorrect =
                              question['selectedAnswer'] ==
                              question['correctAnswer'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),

                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(minWidth: 30),
                                      height: 40,
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        '${index + 1}',
                                        style: CupertinoTheme.of(context)
                                            .textTheme
                                            .textStyle
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              fontFamily: 'Nunito',
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 2,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            question['question'],
                                            style: CupertinoTheme.of(context)
                                                .textTheme
                                                .textStyle
                                                .copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.3,
                                                  color: Colors.grey[800],
                                                  fontFamily: 'Nunito',
                                                ),
                                          ),
                                          const SizedBox(height: 5),
                                          ...((question['options'] as List).map<
                                            Widget
                                          >((option) {
                                            final isSelected =
                                                option['letter'] ==
                                                question['selectedAnswer'];
                                            final isCorrect =
                                                option['letter'] ==
                                                question['correctAnswer'];

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    isCorrect
                                                        ? 'asset/icon/true.png'
                                                        : isSelected
                                                        ? 'asset/icon/wrong.png'
                                                        : 'asset/icon/circle.png',
                                                    width: 20,
                                                    height: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      '${option['letter']} ${option['text']}',
                                                      style: TextStyle(
                                                        fontFamily: 'Nunito',
                                                        decoration:
                                                            TextDecoration.none,
                                                        fontSize: 15,
                                                        color: isCorrect
                                                            ? Colors.green
                                                            : isSelected
                                                            ? CupertinoColors
                                                                  .systemRed
                                                            : Colors.grey[800],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList()),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Image.asset(
                                        isCorrect
                                            ? 'asset/icon/true.png'
                                            : 'asset/icon/wrong.png',
                                        width: 35,
                                        height: 35,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              CupertinoPageRoute(
                                builder: (context) => const QuizPlayScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: const Text(
                              'Tekrar Dene',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Nunito',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 310,
                        child: CupertinoButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const CustomTabBarWidget(initialIndex: 0),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'Ana Sayfaya Dön',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Nunito',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
