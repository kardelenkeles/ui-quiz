import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/new_quiz_provider.dart';
import 'package:ui_quiz/screens/quiz/quiz_result_screen.dart';
import 'package:printing/printing.dart';
import 'dart:convert';
import 'dart:typed_data';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  late final ScrollController _scrollController;
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Quiz geçmişini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NewQuizProvider>(context, listen: false);
      provider.loadQuizHistory();

      // Provider değişikliklerini dinle
      provider.addListener(_providerListener);
    });
  }

  void _showShareOptions(Map<String, dynamic> quiz) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await _shareAsQcm(quiz, includeAnswers: false);
            },
            child: const Text(
              'QCM olarak paylaş',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await _shareAsQcm(quiz, includeAnswers: true);
            },
            child: const Text(
              'QCM (cevap anahtarlı) olarak paylaş',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('İptal', style: TextStyle(fontFamily: 'Nunito')),
        ),
      ),
    );
  }

  Future<void> _shareAsQcm(
    Map<String, dynamic> quiz, {
    bool includeAnswers = false,
  }) async {
    try {
      final qcmText = _generateQcmContent(quiz, includeAnswers: includeAnswers);
      final bytes = Uint8List.fromList(utf8.encode(qcmText));

      // Use printing package to share arbitrary bytes with a filename
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${quiz['title'] ?? 'quiz'}.qcm',
      );
    } catch (e) {
      // Fallback: show an error dialog
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Hata'),
          content: Text('Paylaşma işlemi sırasında hata oluştu: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Tamam'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  String _generateQcmContent(
    Map<String, dynamic> quiz, {
    bool includeAnswers = false,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('[QUIZ]');
    buffer.writeln('Title: ${quiz['title'] ?? 'Untitled'}');
    buffer.writeln('Questions: ${(quiz['questions'] as List).length}');
    buffer.writeln('');

    final questionsRaw = quiz['questions'];
    if (questionsRaw is! List) return '';
    final questions = questionsRaw.cast<Map<String, dynamic>>();
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final questionText = q['question'] is String
          ? q['question'] as String
          : q['question']?.toString() ?? '';
      buffer.writeln('${i + 1}. $questionText');

      final rawOptions = q['options'];
      List<String> options = [];
      if (rawOptions is List) {
        for (var opt in rawOptions) {
          if (opt is String) {
            options.add(opt);
          } else if (opt is Map) {
            // try to get a sensible string from map values
            if (opt.containsKey('text')) {
              options.add(opt['text']?.toString() ?? '');
            } else if (opt.containsKey('label')) {
              options.add(opt['label']?.toString() ?? '');
            } else {
              options.add(opt.values.map((v) => v?.toString() ?? '').join(' '));
            }
          } else {
            options.add(opt?.toString() ?? '');
          }
        }
      }

      for (var j = 0; j < options.length; j++) {
        final optLabel = String.fromCharCode(65 + j); // A, B, C...
        buffer.writeln('   $optLabel) ${options[j]}');
      }

      if (includeAnswers) {
        final correct = q['correctAnswer'] is String
            ? q['correctAnswer'] as String
            : q['correctAnswer']?.toString() ?? '';
        buffer.writeln('   Answer: $correct');
      }

      buffer.writeln('');
    }

    buffer.writeln('[END]');
    return buffer.toString();
  }

  void _providerListener() {
    if (!mounted) return;
    // rebuild so ListView reflects provider.quizHistory changes
    setState(() {});
  }

  int _calculateCorrectAnswers(dynamic questions) {
    if (questions == null) return 0;
    final questionList = questions as List;
    int correct = 0;
    for (var question in questionList) {
      if (question['selectedAnswer'] == question['correctAnswer']) {
        correct++;
      }
    }
    return correct;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Bilinmeyen tarih';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Bilinmeyen tarih';
      }

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day.$month.$year $hour:$minute';
    } catch (e) {
      return 'Bilinmeyen tarih';
    }
  }

  /// Quiz ismini kısalt
  String _getShortQuizName(String fullName) {
    final words = fullName.trim().split(' ');

    // İlk 2-3 kelimeyi al
    if (words.length <= 3) {
      return fullName;
    }

    return words.take(3).join(' ');
  }

  @override
  void dispose() {
    try {
      final provider = Provider.of<NewQuizProvider>(context, listen: false);
      provider.removeListener(_providerListener);
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  void _deleteQuiz(int index) {
    final provider = Provider.of<NewQuizProvider>(context, listen: false);
    if (index < 0 || index >= provider.quizHistory.length) return;
    final removedQuiz = provider.quizHistory[index];

    // Animate removal using the removedQuiz snapshot
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _buildQuizItem(removedQuiz, index),
      ),
      duration: const Duration(milliseconds: 300),
    );

    // Remove from provider list (so subsequent builds reflect removal)
    provider.quizHistory.removeAt(index);

    // Remove from persistent storage (Firebase)
    FirebaseFirestore.instance
        .collection('quizzes')
        .doc(removedQuiz['id'])
        .delete();
  }

  Widget _buildQuizItem(Map<String, dynamic> quiz, int index) {
    // `attempts` and the refresh icon were removed per UI change request
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemGrey4, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getShortQuizName(quiz['title'] as String),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Skor: ${quiz['score'] ?? 0}% - ${_calculateCorrectAnswers(quiz['questions'])}/${(quiz['questions'] as List).length}",
                    style: TextStyle(
                      fontSize: 14,
                      color: (quiz['score'] ?? 0) >= 70
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Tarih: ${_formatDate(quiz['createdAt'])}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.black,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    _showQuizOptions(context, quiz, index);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.ellipsis,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuizOptions(
    BuildContext context,
    Map<String, dynamic> quiz,
    int index,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to quiz result screen
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => QuizResultScreen(
                    correctAnswers: _calculateCorrectAnswers(quiz['questions']),
                    totalQuestions: (quiz['questions'] as List).length,
                    questions: (quiz['questions'] as List)
                        .cast<Map<String, dynamic>>(),
                    quizName: quiz['title'] as String,
                    isFromHistory: true,
                  ),
                ),
              );
            },
            child: const Text(
              'Sonuçları Görüntüle',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showShareOptions(quiz);
            },
            child: const Text('Paylaş', style: TextStyle(fontFamily: 'Nunito')),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteQuiz(index);
            },
            isDestructiveAction: true,
            child: const Text('Sil', style: TextStyle(fontFamily: 'Nunito')),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(fontFamily: 'Nunito')),
        ),
      ),
    );
  }

  // grouping by date was removed in favor of AnimatedList

  @override
  Widget build(BuildContext context) {
    return Consumer<NewQuizProvider>(
      builder: (context, provider, child) {
        return CupertinoPageScaffold(
          child: SafeArea(
            child: Column(
              children: [
                // Geçmiş Quizler başlık kutusu
                Container(
                  width: 170,
                  margin: const EdgeInsets.fromLTRB(0, 36, 156, 20),
                  child: const Text(
                    'quiz history',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                      color: CupertinoColors.black,
                    ),
                  ),
                ),

                // Geçmiş Quizler listesi
                Expanded(
                  child: Builder(
                    builder: (context) {
                      // Use provider state directly; loadQuizHistory is called in initState
                      if (provider.isLoading) {
                        return const Center(
                          child: CupertinoActivityIndicator(),
                        );
                      }

                      if (provider.error.isNotEmpty) {
                        return Center(
                          child: Text(
                            provider.error,
                            style: const TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.systemRed,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        );
                      }

                      if (provider.quizHistory.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async => provider.loadQuizHistory(),
                          child: ListView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'Henüz quiz geçmişiniz yok.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: CupertinoColors.systemGrey,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Has data
                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          CupertinoSliverRefreshControl(
                            onRefresh: () async {
                              await provider.loadQuizHistory();
                            },
                          ),
                          SliverAnimatedList(
                            key: _listKey,
                            initialItemCount: provider.quizHistory.length,
                            itemBuilder: (context, index, animation) {
                              final quiz = provider.quizHistory[index];
                              return SizeTransition(
                                sizeFactor: animation,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      CupertinoPageRoute(
                                        builder: (context) => QuizResultScreen(
                                          correctAnswers:
                                              _calculateCorrectAnswers(
                                                quiz['questions'],
                                              ),
                                          totalQuestions:
                                              (quiz['questions'] as List)
                                                  .length,
                                          questions: (quiz['questions'] as List)
                                              .cast<Map<String, dynamic>>(),
                                          quizName: quiz['title'] as String,
                                          isFromHistory: true,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _buildQuizItem(quiz, index),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
