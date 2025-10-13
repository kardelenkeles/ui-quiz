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
    final attempts = (quiz['attempts'] as int?) ?? 0;
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
                // If attempts >= 1, show sync chip (shows number of attempts)
                if (attempts >= 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Container(
                      width: 30,
                      height: 30,

                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Asset icon (if available)
                            Image.asset(
                              'asset/icon/refresh.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                              // silently fail to fallback below
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
              // Add share functionality here
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
