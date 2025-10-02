import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ui_quiz/screens/quiz_list_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final List<Map<String, dynamic>> staticQuestions = [
    {
      'question': 'Flutter hangi programlama diliyle geliştirilir?',
      'options': [
        {'letter': 'A.', 'text': 'Java'},
        {'letter': 'B.', 'text': 'Dart'},
        {'letter': 'C.', 'text': 'Kotlin'},
        {'letter': 'D.', 'text': 'Swift'},
      ],
      'correctAnswer': 'B.',
      'selectedAnswer': null,
    },
    {
      'question': 'Widget nedir?',
      'options': [
        {'letter': 'A', 'text': 'Bir programlama dili'},
        {'letter': 'B', 'text': 'Bir veritabanı'},
        {'letter': 'C', 'text': 'Flutter\'da UI bileşeni'},
        {'letter': 'D', 'text': 'Bir sunucu'},
      ],
      'correctAnswer': 'C',
      'selectedAnswer': null,
    },
    {
      'question': 'StatefulWidget ve StatelessWidget arasındaki fark nedir?',
      'options': [
        {'letter': 'A', 'text': 'Hiçbir fark yok'},
        {'letter': 'B', 'text': 'StatefulWidget durumu değişebilir'},
        {'letter': 'C', 'text': 'StatelessWidget daha hızlıdır'},
        {'letter': 'D', 'text': 'StatefulWidget sadece iOS\'ta çalışır'},
      ],
      'correctAnswer': 'B',
      'selectedAnswer': null,
    },
    {
      'question': 'Hot Reload özelliği ne işe yarar?',
      'options': [
        {'letter': 'A', 'text': 'Uygulamayı yeniden başlatır'},
        {'letter': 'B', 'text': 'Kodu anında günceller'},
        {'letter': 'C', 'text': 'Uygulamayı yayınlar'},
        {'letter': 'D', 'text': 'Hata ayıklar'},
      ],
      'correctAnswer': 'B',
      'selectedAnswer': null,
    },
  ];

  int currentQuestionIndex = 0;
  bool _isBackPressed = false;
  bool _isForwardPressed = false;
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        leading: CupertinoButton(
          padding: const EdgeInsets.all(15),
          onPressed: () {
            _showExitConfirmation();
          },
          child: const Icon(
            CupertinoIcons.xmark,
            color: CupertinoColors.systemRed,
            size: 24,
          ),
        ),
      ),
      child: _buildStaticQuizUI(),
    );
  }

  Widget _buildStaticQuizUI() {
    final questionData = staticQuestions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / staticQuestions.length;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildLinearProgressBar(progress),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: CupertinoColors.systemGrey6.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    questionData['question'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Expanded(
                child: ListView.builder(
                  itemCount: (questionData['options'] as List).length,
                  itemBuilder: (context, index) {
                    final options =
                        questionData['options'] as List<Map<String, String>>;
                    final option = options[index];
                    final isSelected =
                        questionData['selectedAnswer'] == option['letter'];
                    final isCorrect =
                        questionData['correctAnswer'] == option['letter'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 26),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isCorrect
                                  ? CupertinoColors.systemGreen.withOpacity(
                                      0.15,
                                    )
                                  : CupertinoColors.systemRed.withOpacity(0.15))
                            : CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (isCorrect
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.systemRed)
                              : CupertinoColors.systemGrey4,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(
                              color: CupertinoColors.systemGrey.withOpacity(
                                0.1,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          if (isSelected)
                            BoxShadow(
                              color:
                                  (isCorrect
                                          ? CupertinoColors.systemGreen
                                          : CupertinoColors.systemRed)
                                      .withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(20),
                        onPressed: () {
                          if (questionData['selectedAnswer'] == null) {
                            setState(() {
                              staticQuestions[currentQuestionIndex]['selectedAnswer'] =
                                  option['letter'];
                            });
                          }
                        },
                        child: Row(
                          children: [
                            Text(
                              option['letter']!,
                              style: TextStyle(
                                color: isSelected
                                    ? (isCorrect
                                          ? CupertinoColors.systemGreen
                                          : CupertinoColors.systemRed)
                                    : CupertinoColors.label,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option['text']!,
                                style: TextStyle(
                                  color: CupertinoColors.label,
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color:
                                      (isCorrect
                                              ? CupertinoColors.systemGreen
                                              : CupertinoColors.systemRed)
                                          .withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCorrect
                                      ? CupertinoIcons.check_mark
                                      : CupertinoIcons.xmark,
                                  color: isCorrect
                                      ? CupertinoColors.systemGreen
                                      : CupertinoColors.systemRed,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Navigation ikonları
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTapDown: currentQuestionIndex == 0
                        ? null
                        : (_) {
                            setState(() {
                              _isBackPressed = true;
                            });
                          },
                    onTapUp: currentQuestionIndex == 0
                        ? null
                        : (_) {
                            setState(() {
                              _isBackPressed = false;
                            });
                          },
                    onTapCancel: currentQuestionIndex == 0
                        ? null
                        : () {
                            setState(() {
                              _isBackPressed = false;
                            });
                          },
                    onTap: currentQuestionIndex == 0
                        ? null
                        : () {
                            setState(() {
                              currentQuestionIndex--;
                            });
                          },
                    child: AnimatedScale(
                      scale: _isBackPressed ? 0.85 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: AnimatedOpacity(
                        opacity: _isBackPressed ? 0.6 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Opacity(
                          opacity: currentQuestionIndex == 0 ? 0.3 : 1.0,
                          child: Image.asset(
                            'asset/icon/arrow-left.png',
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTapDown: questionData['selectedAnswer'] == null
                        ? null
                        : (_) {
                            setState(() {
                              _isForwardPressed = true;
                            });
                          },
                    onTapUp: questionData['selectedAnswer'] == null
                        ? null
                        : (_) {
                            setState(() {
                              _isForwardPressed = false;
                            });
                          },
                    onTapCancel: questionData['selectedAnswer'] == null
                        ? null
                        : () {
                            setState(() {
                              _isForwardPressed = false;
                            });
                          },
                    onTap: questionData['selectedAnswer'] == null
                        ? null
                        : () {
                            if (currentQuestionIndex ==
                                staticQuestions.length - 1) {
                              _showStaticQuizResult();
                            } else {
                              setState(() {
                                currentQuestionIndex++;
                              });
                            }
                          },
                    child: AnimatedScale(
                      scale: _isForwardPressed ? 0.85 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: AnimatedOpacity(
                        opacity: _isForwardPressed ? 0.6 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Opacity(
                          opacity: questionData['selectedAnswer'] == null
                              ? 0.3
                              : 1.0,
                          child: Image.asset(
                            currentQuestionIndex == staticQuestions.length - 1
                                ? 'asset/icon/complete.png'
                                : 'asset/icon/arrow-right.png',
                            width: 40,
                            height: 40,
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
        // Question counter positioned at top-right
        Positioned(
          top: 10,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${currentQuestionIndex + 1} / ${staticQuestions.length}',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinearProgressBar(double progress) {
    final totalWidth = MediaQuery.of(context).size.width - 90;

    return SizedBox(
      width: totalWidth,
      height: 80,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            width: totalWidth,
            height: 8,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1),
                  width: totalWidth * progress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF72F2F), Color(0xFFFF6F6F)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: (totalWidth * progress).clamp(0, totalWidth - 40),
            top: 15,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'asset/icon/pomegranate.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Quiz\'den Çık'),
        content: const Text(
          'Quiz\'den çıkmak istediğinizden emin misiniz? İlerlemeniz kaybolacak.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('İptal'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Çık'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (context) => const QuizListScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showStaticQuizResult() {
    int correctAnswers = 0;
    for (var question in staticQuestions) {
      if (question['selectedAnswer'] == question['correctAnswer']) {
        correctAnswers++;
      }
    }

    final successRate = (correctAnswers / staticQuestions.length * 100);
    final isSuccess = successRate >= 70; // %70 üzeri başarılı sayılsın

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          // Tam ekran confetti animasyonu (sadece başarılı olduğunda)
          if (isSuccess)
            Positioned.fill(
              child: Lottie.asset(
                'asset/animations/Confetti.json',
                repeat: true,
                animate: true,
                fit: BoxFit.cover,
              ),
            ),

          // Dialog merkeze yerleştirildi
          Center(
            child: CupertinoAlertDialog(
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başarısız durumda küçük animasyon
                  if (!isSuccess)
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: Lottie.asset(
                        'asset/animations/fall.json',
                        repeat: true,
                        animate: true,
                      ),
                    ),
                  SizedBox(height: isSuccess ? 20 : 10),
                  Text(
                    isSuccess ? 'Tebrikler! 🎉' : 'Daha İyi Olabilir! 💪',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Doğru cevap sayısı: $correctAnswers / ${staticQuestions.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? CupertinoColors.systemGreen.withOpacity(0.1)
                            : CupertinoColors.systemOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSuccess
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemOrange,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Başarı oranı: ${successRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSuccess
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Tekrar Dene'),
                  onPressed: () {
                    setState(() {
                      currentQuestionIndex = 0;
                      for (var question in staticQuestions) {
                        question['selectedAnswer'] = null;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: const Text('Kapat'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      CupertinoPageRoute(
                        builder: (context) => const QuizListScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
