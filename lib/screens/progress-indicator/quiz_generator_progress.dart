import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:ui_quiz/services/file_text_extractor.dart';
import 'package:ui_quiz/providers/new_quiz_provider.dart';
import 'package:ui_quiz/screens/quiz/quiz_questions_review.dart';

class QuizGeneratorProgressScreen extends StatefulWidget {
  final String inputText;
  final String? fileContent;
  final List<int>? selectedPages;
  final String? filePath;
  final String? originalFileName;
  final int questionCount;
  final String difficulty;

  const QuizGeneratorProgressScreen({
    super.key,
    required this.inputText,
    this.fileContent,
    this.selectedPages,
    this.filePath,
    this.originalFileName,
    this.questionCount = 10,
    this.difficulty = 'mid',
  });

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

    // Build tamamlandıktan sonra başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGenerationProcess();
    });
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

    // API çağrısını biraz geciktir
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _generateQuizWithAPI();
      }
    });
  }

  Future<void> _generateQuizWithAPI() async {
    try {
      final provider = Provider.of<NewQuizProvider>(context, listen: false);

      // Quiz oluştur - inputText'i topic olarak kullan
      String? fileContent = widget.fileContent;

      // If selectedPages specified and a filePath is provided, extract only those pages
      if ((widget.selectedPages?.isNotEmpty ?? false) &&
          widget.filePath != null) {
        try {
          final f = File(widget.filePath!);
          fileContent = await FileTextExtractor.extractText(
            f,
            pages: widget.selectedPages,
          );
        } catch (e) {
          // fallback to provided fileContent
        }
      }

      final success = await provider.generateQuiz(
        topic: widget.inputText,
        questionCount: widget.questionCount,
        difficulty: widget.difficulty,
        fileContent: fileContent,
        originalFileName: widget.originalFileName,
        filePath: widget.filePath,
      );

      if (mounted) {
        if (!success || provider.error.isNotEmpty) {
          _showErrorAndGoBack(
            provider.error.isEmpty
                ? 'Bilinmeyen bir hata oluştu'
                : provider.error,
          );
        } else {
          _navigateToReviewWithRealData(provider.currentQuestions);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorAndGoBack('Quiz oluşturulurken bir hata oluştu: $e');
      }
    }
  }

  void _showErrorAndGoBack(String errorMessage) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hata'),
        content: Text(errorMessage),
        actions: [
          CupertinoDialogAction(
            child: const Text('Tamam'),
            onPressed: () {
              Navigator.of(context).pop(); // Dialog'u kapat
              Navigator.of(context).pop(); // Progress screen'i kapat
            },
          ),
        ],
      ),
    );
  }

  void _navigateToReviewWithRealData(List<Map<String, dynamic>> questions) {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => QuizQuestionsReviewScreen(questions: questions),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animasyonu
              SizedBox(
                width: 220, // Increased size
                height: 220, // Increased size
                child: Lottie.asset(
                  'asset/animations/animation.json',
                  repeat: true,
                  animate: true,
                  controller: _animationController, // Attach controller
                  onLoaded: (composition) {
                    _animationController
                      ..duration = composition.duration
                      ..forward(from: 0.2); // Skip the first half second
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
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
                              colors: [
                                Colors.lime,
                                CupertinoColors.systemOrange,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    },
                  ),
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
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 50),

              // İptal butonu
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'İptal Et',
                  style: TextStyle(
                    color: Colors.black,
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
