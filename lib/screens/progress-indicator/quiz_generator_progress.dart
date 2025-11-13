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
    'Analyzing text...',
    'Creating questions...',
    'Preparing answer choices...',
    'Determining correct answers...',
    'Finalizing quiz...',
  ];

  int _currentTextIndex = 0;
  DateTime? _startTime;
  Timer? _progressTimer;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

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

    // Progress bar'ı gerçek zamanlı güncelle
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;

      // Dinamik tahmin: İlk 5 saniyede hızlı, sonra yavaşla
      double progressValue;
      if (elapsed < 5000) {
        // İlk 5 saniyede %50'ye kadar hızlı ilerle
        progressValue = (elapsed / 5000) * 0.5;
      } else if (elapsed < 15000) {
        // 5-15 saniye arası %50'den %85'e
        progressValue = 0.5 + ((elapsed - 5000) / 10000) * 0.35;
      } else {
        // 15 saniye sonrası çok yavaş ilerle, %95'i geçme
        final overtime = elapsed - 15000;
        progressValue = 0.85 + (overtime / 30000) * 0.1; // 30 saniyede %10 daha
        progressValue = progressValue.clamp(0.0, 0.95);
      }

      setState(() {
        _currentProgress = progressValue;

        // Text index'i progress'e göre güncelle
        final textProgress = (_currentProgress * _loadingTexts.length).floor();
        _currentTextIndex = textProgress.clamp(0, _loadingTexts.length - 1);
      });
    });

    // API çağrısını hemen başlat
    _generateQuizWithAPI();
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
        // Progress'i %100'e tamamla
        setState(() {
          _currentProgress = 1.0;
          _currentTextIndex = _loadingTexts.length - 1;
        });

        // Kısa bir gecikme ile tamamlanma hissi ver
        await Future.delayed(const Duration(milliseconds: 500));

        if (!success || provider.error.isNotEmpty) {
          _showErrorAndGoBack(
            provider.error.isEmpty
                ? 'An unknown error occurred'
                : provider.error,
          );
        } else {
          _navigateToReviewWithRealData(provider.currentQuestions);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorAndGoBack('An error occurred while creating quiz: $e');
      }
    }
  }

  void _showErrorAndGoBack(String errorMessage) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close progress screen
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
    _progressTimer?.cancel();
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
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _currentProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.lime, CupertinoColors.systemOrange],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Progress yüzdesi
              Text(
                '${(_currentProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.lime,
                ),
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

              // Cancel button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
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
