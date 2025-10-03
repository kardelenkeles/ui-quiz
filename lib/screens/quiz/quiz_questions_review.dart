import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:transformable_list_view/transformable_list_view.dart';
import 'package:ui_quiz/screens/quiz/quiz_play.dart';

Matrix4 getTransformMatrix(TransformableListItem item) {
  const endScaleBound = 0.3;
  final animationProgress = item.visibleExtent / item.size.height;
  final paintTransform = Matrix4.identity();

  if (item.position != TransformableListItemPosition.middle) {
    final scale = endScaleBound + ((1 - endScaleBound) * animationProgress);

    paintTransform
      ..translate(item.size.width / 2)
      ..scale(scale)
      ..translate(-item.size.width / 2);
  }

  return paintTransform;
}

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

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _playDeleteAnimation(GlobalKey key) async {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) {
          return Positioned(
            top: renderBox.localToGlobal(Offset.zero).dy,
            left: renderBox.localToGlobal(Offset.zero).dx,
            child: Icon(CupertinoIcons.trash, color: Colors.red, size: 40),
          );
        },
      );
      overlay.insert(overlayEntry);
      await Future.delayed(const Duration(milliseconds: 500));
      overlayEntry.remove();
    }
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
              child: TransformableListView.builder(
                itemCount: _questions.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                getTransformMatrix: getTransformMatrix,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  final isSelected = question['isSelected'] ?? false;
                  final deleteIconKey = GlobalKey();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.lime
                            : CupertinoColors.systemGrey4,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            question['question'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          key: deleteIconKey,
                          onTap: () async {
                            await _playDeleteAnimation(deleteIconKey);
                            _deleteQuestion(index);
                          },
                          child: const Icon(
                            CupertinoIcons.trash,
                            color: Colors.red,
                          ),
                        ),
                      ],
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
