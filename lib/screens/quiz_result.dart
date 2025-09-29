import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';

@RoutePage()
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final score = quizProvider.score;
    final totalQuestions = quizProvider.totalQuestions;
    final percentage = totalQuestions > 0 ? (score / totalQuestions * 100) : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Sonucu'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Skor kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    Text(
                      _getResultMessage(percentage.toDouble()),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 10,
                      color: _getScoreColor(percentage.toDouble()),
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$score / $totalQuestions',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}% Doğru',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Detaylı sonuçlar
            Expanded(
              child: ListView.builder(
                itemCount: quizProvider.currentQuiz?.questions.length ?? 0,
                itemBuilder: (context, index) {
                  final question = quizProvider.currentQuiz!.questions[index];
                  final isCorrect = question.isCorrect;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: isCorrect ? Colors.green[50] : Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Soru ${index + 1}: ${question.question}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Senin cevabın: ${question.selectedAnswer ?? "Cevaplanmadı"}',
                            style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Doğru cevap: ${question.correctAnswer}'),
                          const SizedBox(height: 10),
                          Text(
                            'Açıklama: ${question.explanation}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      quizProvider.resetQuiz();
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Ana Sayfa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      quizProvider.resetQuiz();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeni Quiz'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getResultMessage(double percentage) {
    if (percentage >= 90) return 'Mükemmel! 🎉';
    if (percentage >= 70) return 'Çok İyi! 👍';
    if (percentage >= 50) return 'İyi! 😊';
    if (percentage >= 30) return 'Daha iyi olabilir 🤔';
    return 'Tekrar deneyin 📚';
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 70) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}
