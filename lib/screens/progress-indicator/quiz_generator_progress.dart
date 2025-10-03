import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ui_quiz/screens/quiz/quiz_questions_review.dart';

class QuizGeneratorProgressScreen extends StatefulWidget {
  final String inputText;

  const QuizGeneratorProgressScreen({super.key, required this.inputText});

  @override
  State<QuizGeneratorProgressScreen> createState() =>
      _QuizGeneratorProgressScreenState();
}

class _QuizGeneratorProgressScreenState
    extends State<QuizGeneratorProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  final List<String> _loadingTexts = [
    'Metni analiz ediliyor...',
    'Sorular oluşturuluyor...',
    'Cevap şıkları hazırlanıyor...',
    'Quiz tamamlanıyor...',
  ];

  int _currentTextIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startGenerationProcess();
  }

  void _startGenerationProcess() {
    _animationController.forward();

    // Metin değiştirme animasyonu
    Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted && _currentTextIndex < _loadingTexts.length - 1) {
        setState(() {
          _currentTextIndex++;
        });
      } else {
        timer.cancel();
      }
    });

    // 4 saniye sonra sonuç sayfasına geç
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _navigateToReview();
      }
    });
  }

  void _navigateToReview() {
    // Örnek sorular oluştur (gerçek uygulamada API'den gelecek)
    final generatedQuestions = _generateMockQuestions();

    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) =>
            QuizQuestionsReviewScreen(questions: generatedQuestions),
      ),
    );
  }

  List<Map<String, dynamic>> _generateMockQuestions() {
    return [
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
        'isSelected': true, // Bu soru seçili
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
        'isSelected': true,
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
        'isSelected': true,
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
        'isSelected': false, // Bu soru seçili değil
      },
      {
        'question':
            'Flutter\'da State Management için hangi yaklaşım kullanılabilir?',
        'options': [
          {'letter': 'A', 'text': 'Provider'},
          {'letter': 'B', 'text': 'BLoC'},
          {'letter': 'C', 'text': 'Riverpod'},
          {'letter': 'D', 'text': 'Hepsi'},
        ],
        'correctAnswer': 'D',
        'selectedAnswer': null,
        'isSelected': true,
      },
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        leading: CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.systemBlue,
          ),
        ),
        middle: const Text(
          'Quiz Oluşturuluyor',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animasyonu
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  'asset/animations/Happy-Star.json',
                  repeat: true,
                  animate: true,
                ),
              ),

              const SizedBox(height: 40),

              // Progress bar
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.lime, Colors.green],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Progress yüzdesi
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Text(
                    '${(_progressAnimation.value * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.lime,
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Loading metni
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _loadingTexts[_currentTextIndex],
                  key: ValueKey(_currentTextIndex),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 50),

              // İptal butonu
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(12),
                child: const Text(
                  'İptal Et',
                  style: TextStyle(
                    color: CupertinoColors.label,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
