import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/new_quiz_provider.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';
import 'package:ui_quiz/screens/quiz/quiz_play.dart';

class QuizResultScreen extends StatefulWidget {
  final int correctAnswers;
  final int totalQuestions;
  final List<Map<String, dynamic>> questions;
  final String? quizName;
  final bool isFromHistory;

  const QuizResultScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.questions,
    this.quizName,
    this.isFromHistory = false,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late final ScrollController _scrollController;
  bool _hasBeenSaved = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Quiz sonucunu kaydet (sadece yeni quiz'ler için, history'den gelenler için değil)
    if (!widget.isFromHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _saveQuizResult();
      });
    }
  }

  Future<void> _saveQuizResult() async {
    if (_hasBeenSaved) return; // Zaten kaydedildiyse tekrar kaydetme

    try {
      _hasBeenSaved = true; // Flag'i set et
      final provider = Provider.of<NewQuizProvider>(context, listen: false);

      // Quiz sonucunu kaydet
      await provider.saveQuizResult(
        quizTitle: widget.quizName ?? 'Quiz',
        questions: widget.questions,
        correctAnswers: widget.correctAnswers,
        totalQuestions: widget.totalQuestions,
      );

      print('Quiz result saved successfully');
    } catch (e) {
      _hasBeenSaved = false; // Hata durumunda flag'i reset et
      print('Error saving quiz result: $e');
    }
  }

  /// Quiz ismini kısalt
  String _getShortQuizName() {
    if (widget.quizName == null) return 'Quiz';

    final words = widget.quizName!.trim().split(' ');

    // İlk 2-3 kelimeyi al
    if (words.length <= 5) {
      return widget.quizName!;
    }

    return words.take(3).join(' ');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final successRate = (widget.correctAnswers / widget.totalQuestions * 100);
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

          // Geri butonu - sadece history'den açılanlar için
          if (widget.isFromHistory)
            Positioned(
              top: 45,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Icon(
                    CupertinoIcons.back,
                    color: CupertinoColors.black,
                    size: 24,
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const SizedBox(height: 5),

                  // Quiz adı
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _getShortQuizName(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
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
                                '${widget.correctAnswers} / ${widget.totalQuestions} doğru',
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

                  // Cevaplar listesi - Expanded ile kalan alanı kapla
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      radius: const Radius.circular(8),
                      thickness: 2,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: widget.questions.length,
                        itemBuilder: (context, index) {
                          final question = widget.questions[index];
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
                                      constraints: const BoxConstraints(
                                        minWidth: 30,
                                      ),
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
                                Flexible(
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
                                            final isCorrectOption =
                                                option['letter'] ==
                                                question['correctAnswer'];

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    isCorrectOption
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
                                                        color: isCorrectOption
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
                        width: 350,
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
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 300,
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
