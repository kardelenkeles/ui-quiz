import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
        {'letter': 'A', 'text': 'Java'},
        {'letter': 'B', 'text': 'Dart'},
        {'letter': 'C', 'text': 'Kotlin'},
        {'letter': 'D', 'text': 'Swift'},
      ],
      'correctAnswer': 'B',
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
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(child: _buildStaticQuizUI());
  }

  Widget _buildStaticQuizUI() {
    final questionData = staticQuestions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / staticQuestions.length;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildLinearProgressBar(progress),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
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
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Soru ${currentQuestionIndex + 1} / ${staticQuestions.length}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    questionData['question'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Seçenekler
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
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isCorrect
                              ? CupertinoColors.systemGreen.withOpacity(0.15)
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
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
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
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isCorrect
                                      ? CupertinoColors.systemGreen
                                      : CupertinoColors.systemRed)
                                : CupertinoColors.inactiveGray,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isSelected
                                            ? (isCorrect
                                                  ? CupertinoColors.systemGreen
                                                  : CupertinoColors.systemRed)
                                            : CupertinoColors.activeBlue)
                                        .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              option['letter']!,
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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

          // Navigation butonları
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  onPressed: currentQuestionIndex == 0
                      ? null
                      : () {
                          setState(() {
                            currentQuestionIndex--;
                          });
                        },
                  color: CupertinoColors.systemGrey,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.back, color: CupertinoColors.white),
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
                  onPressed: questionData['selectedAnswer'] == null
                      ? null
                      : () {
                          if (currentQuestionIndex ==
                              staticQuestions.length - 1) {
                            // Son soru - sonuç ekranına git
                            _showStaticQuizResult();
                          } else {
                            setState(() {
                              currentQuestionIndex++;
                            });
                          }
                        },
                  color: CupertinoColors.activeBlue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        currentQuestionIndex == staticQuestions.length - 1
                            ? CupertinoIcons.flag
                            : CupertinoIcons.forward,
                        color: CupertinoColors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentQuestionIndex == staticQuestions.length - 1
                            ? 'Bitir'
                            : 'İleri',
                        style: const TextStyle(color: CupertinoColors.white),
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
  }

  Widget _buildLinearProgressBar(double progress) {
    final totalWidth = MediaQuery.of(context).size.width - 90;

    return SizedBox(
      width: totalWidth,
      height: 80,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Progress bar
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
                  duration: const Duration(milliseconds: 400),
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

  void _showStaticQuizResult() {
    int correctAnswers = 0;
    for (var question in staticQuestions) {
      if (question['selectedAnswer'] == question['correctAnswer']) {
        correctAnswers++;
      }
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Quiz Tamamlandı!'),
        content: Text(
          'Doğru cevap sayısı: $correctAnswers / ${staticQuestions.length}\n'
          'Başarı oranı: ${(correctAnswers / staticQuestions.length * 100).toStringAsFixed(1)}%',
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
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
