import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ui_quiz/screens/quiz/quiz_play.dart';

class QuizQuestionsReviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;

  const QuizQuestionsReviewScreen({super.key, required this.questions});

  @override
  State<QuizQuestionsReviewScreen> createState() =>
      _QuizQuestionsReviewScreenState();
}

class _QuizQuestionsReviewScreenState extends State<QuizQuestionsReviewScreen> {
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions);
  }

  void _toggleQuestionSelection(int index) {
    setState(() {
      _questions[index]['isSelected'] = !_questions[index]['isSelected'];
    });
  }

  void _selectAllQuestions() {
    setState(() {
      for (var question in _questions) {
        question['isSelected'] = true;
      }
    });
  }

  void _deselectAllQuestions() {
    setState(() {
      for (var question in _questions) {
        question['isSelected'] = false;
      }
    });
  }

  void _startQuiz() {
    final selectedQuestions = _questions
        .where((question) => question['isSelected'] == true)
        .toList();

    if (selectedQuestions.isEmpty) {
      _showAlert('Uyarı', 'Lütfen en az bir soru seçin.');
      return;
    }

    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => QuizPlayScreen(questions: selectedQuestions),
      ),
    );
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  int get _selectedCount =>
      _questions.where((q) => q['isSelected'] == true).length;

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
          'Soruları İncele',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selectedCount > 0 ? _startQuiz : null,
          child: Text(
            'Başla',
            style: TextStyle(
              color: _selectedCount > 0
                  ? CupertinoColors.systemBlue
                  : CupertinoColors.systemGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Üst bilgi paneli
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Toplam: ${_questions.length} soru',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Seçili: $_selectedCount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedCount > 0
                              ? Colors.lime
                              : CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          onPressed: _selectAllQuestions,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          color: CupertinoColors.systemBlue,
                          borderRadius: BorderRadius.circular(8),
                          child: const Text(
                            'Tümünü Seç',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoButton(
                          onPressed: _deselectAllQuestions,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          color: CupertinoColors.systemGrey4,
                          borderRadius: BorderRadius.circular(8),
                          child: const Text(
                            'Tümünü Kaldır',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sorular listesi
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  final isSelected = question['isSelected'] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.lime
                            : CupertinoColors.systemGrey4,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _toggleQuestionSelection(index),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Soru başlığı ve seçim durumu
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.lime
                                        : CupertinoColors.systemGrey5,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          CupertinoIcons.check_mark,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Soru ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.lime
                                          : CupertinoColors.label,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Soru metni
                            Text(
                              question['question'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.label,
                                height: 1.3,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Şıklar (kısaltılmış görünüm)
                            Column(
                              children: (question['options'] as List)
                                  .take(2) // Sadece ilk 2 şıkkı göster
                                  .map<Widget>((option) {
                                    final isCorrect =
                                        option['letter'] ==
                                        question['correctAnswer'];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCorrect
                                            ? CupertinoColors.systemGreen
                                                  .withOpacity(0.1)
                                            : CupertinoColors.systemGrey6,
                                        borderRadius: BorderRadius.circular(8),
                                        border: isCorrect
                                            ? Border.all(
                                                color:
                                                    CupertinoColors.systemGreen,
                                                width: 1,
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            option['letter'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isCorrect
                                                  ? CupertinoColors.systemGreen
                                                  : CupertinoColors
                                                        .secondaryLabel,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              option['text'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: CupertinoColors
                                                    .secondaryLabel,
                                              ),
                                            ),
                                          ),
                                          if (isCorrect)
                                            const Icon(
                                              CupertinoIcons
                                                  .check_mark_circled_solid,
                                              size: 16,
                                              color:
                                                  CupertinoColors.systemGreen,
                                            ),
                                        ],
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),

                            if ((question['options'] as List).length > 2)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '+ ${(question['options'] as List).length - 2} şık daha',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.systemGrey,
                                    fontStyle: FontStyle.italic,
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

            // Alt buton
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _selectedCount > 0 ? _startQuiz : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Text(
                    'Quiz\'i Başlat ($_selectedCount soru)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
