import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  // Örnek geçmiş quiz verileri
  final List<Map<String, dynamic>> pastQuizzes = [
    {
      'title': 'Flutter Temelleri Quiz',
      'date': '28 Eylül 2025',
      'score': 85,
      'totalQuestions': 10,
      'correctAnswers': 8,
      'duration': '5 dakika',
      'category': 'Flutter',
      'difficulty': 'Kolay',
      'badge': '🏆',
    },
    {
      'title': 'Dart Programlama Quiz',
      'date': '25 Eylül 2025',
      'score': 70,
      'totalQuestions': 15,
      'correctAnswers': 10,
      'duration': '8 dakika',
      'category': 'Dart',
      'difficulty': 'Orta',
      'badge': '🥈',
    },
    {
      'title': 'Widget Mimarisi Quiz',
      'date': '22 Eylül 2025',
      'score': 95,
      'totalQuestions': 12,
      'correctAnswers': 11,
      'duration': '6 dakika',
      'category': 'Flutter',
      'difficulty': 'Zor',
      'badge': '🥇',
    },
    {
      'title': 'State Management Quiz',
      'date': '20 Eylül 2025',
      'score': 60,
      'totalQuestions': 8,
      'correctAnswers': 5,
      'duration': '4 dakika',
      'category': 'Flutter',
      'difficulty': 'Orta',
      'badge': '🥉',
    },
    {
      'title': 'Async Programming Quiz',
      'date': '18 Eylül 2025',
      'score': 88,
      'totalQuestions': 10,
      'correctAnswers': 9,
      'duration': '7 dakika',
      'category': 'Dart',
      'difficulty': 'Zor',
      'badge': '🏆',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        middle: Text(
          'Geçmiş Quizler',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // İstatistik Özeti
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    '${pastQuizzes.length}',
                    'Toplam Quiz',
                    CupertinoColors.systemBlue,
                    '📚',
                  ),
                  _buildStatCard(
                    '${_calculateAverageScore()}%',
                    'Ortalama Puan',
                    CupertinoColors.systemGreen,
                    '📊',
                  ),
                  _buildStatCard(
                    '${_getBestScore()}%',
                    'En Yüksek Puan',
                    CupertinoColors.systemOrange,
                    '🏆',
                  ),
                ],
              ),
            ),

            // Quiz Listesi
            Expanded(
              child: pastQuizzes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: pastQuizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = pastQuizzes[index];
                        return _buildQuizCard(quiz, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String title, Color color, String emoji) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz, int index) {
    final Color scoreColor = _getScoreColor(quiz['score']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showQuizDetails(quiz),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Badge ve Skor
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scoreColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(quiz['badge'], style: const TextStyle(fontSize: 20)),
                    Text(
                      '${quiz['score']}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Quiz Bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              quiz['category'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            quiz['category'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _getCategoryColor(quiz['category']),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(
                              quiz['difficulty'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            quiz['difficulty'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _getDifficultyColor(quiz['difficulty']),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${quiz['correctAnswers']}/${quiz['totalQuestions']} doğru',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          quiz['duration'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quiz['date'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey3,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.book,
              size: 40,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Henüz Quiz Çözmediniz',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İlk quiz\'inizi çözmek için\nana sayfaya gidin',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }

  void _showQuizDetails(Map<String, dynamic> quiz) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(quiz['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildDetailRow('Tarih:', quiz['date']),
            _buildDetailRow('Kategori:', quiz['category']),
            _buildDetailRow('Zorluk:', quiz['difficulty']),
            _buildDetailRow('Puan:', '${quiz['score']}%'),
            _buildDetailRow(
              'Doğru Cevap:',
              '${quiz['correctAnswers']}/${quiz['totalQuestions']}',
            ),
            _buildDetailRow('Süre:', quiz['duration']),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Tekrar Çöz'),
            onPressed: () {
              Navigator.of(context).pop();
              // Quiz'i tekrar çözme fonksiyonu burada çağrılabilir
            },
          ),
          CupertinoDialogAction(
            child: const Text('Kapat'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAverageScore() {
    if (pastQuizzes.isEmpty) return 0;
    int totalScore = pastQuizzes.fold(
      0,
      (sum, quiz) => sum + (quiz['score'] as int),
    );
    return (totalScore / pastQuizzes.length).round();
  }

  int _getBestScore() {
    if (pastQuizzes.isEmpty) return 0;
    return pastQuizzes
        .map((quiz) => quiz['score'] as int)
        .reduce((a, b) => a > b ? a : b);
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return CupertinoColors.systemGreen;
    if (score >= 70) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'flutter':
        return CupertinoColors.systemBlue;
      case 'dart':
        return CupertinoColors.systemPurple;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'kolay':
        return CupertinoColors.systemGreen;
      case 'orta':
        return CupertinoColors.systemOrange;
      case 'zor':
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
