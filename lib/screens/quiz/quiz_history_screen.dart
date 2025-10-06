import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/new_quiz_provider.dart';
import 'package:ui_quiz/screens/quiz/quiz_result_screen.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Quiz geçmişini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuizHistory();
    });
  }

  Future<void> _loadQuizHistory() async {
    final provider = Provider.of<NewQuizProvider>(context, listen: false);
    await provider.loadQuizHistory();
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

      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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
    _scrollController.dispose();
    super.dispose();
  }

  void _showQuizOptions(BuildContext context, Map<String, dynamic> quiz) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          _getShortQuizName(quiz["title"] as String),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
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
              // Add share functionality here
            },
            child: const Text('Paylaş', style: TextStyle(fontFamily: 'Nunito')),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Add delete functionality here
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
                  margin: const EdgeInsets.fromLTRB(0, 36, 156, 36),
                  padding: const EdgeInsets.all(16.0),

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
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    thickness: 4,
                    child: provider.quizHistory.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.doc_text,
                                  size: 64,
                                  color: CupertinoColors.systemGrey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Henüz quiz geçmişiniz yok',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: CupertinoColors.systemGrey,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'İlk quiz\'inizi oluşturun!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.systemGrey2,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: provider.quizHistory.length,
                            itemBuilder: (context, index) {
                              final quiz = provider.quizHistory[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) => QuizResultScreen(
                                        correctAnswers:
                                            _calculateCorrectAnswers(
                                              quiz['questions'],
                                            ),
                                        totalQuestions:
                                            (quiz['questions'] as List).length,
                                        questions: (quiz['questions'] as List)
                                            .cast<Map<String, dynamic>>(),
                                        quizName: quiz['title'] as String,
                                        isFromHistory: true,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: CupertinoColors.systemGrey4,
                                        width: 1.5,
                                      ),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getShortQuizName(
                                                  quiz['title'] as String,
                                                ),
                                                style: TextStyle(
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
                                                  color:
                                                      (quiz['score'] ?? 0) >= 70
                                                      ? CupertinoColors
                                                            .systemGreen
                                                      : CupertinoColors
                                                            .systemOrange,
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
                                        // Three dots menu icon
                                        GestureDetector(
                                          onTap: () {
                                            // Add menu options here (edit, delete, share, etc.)
                                            _showQuizOptions(context, quiz);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  CupertinoColors.systemGrey6,
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                  ),
                                ),
                              );
                            },
                          ),
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
