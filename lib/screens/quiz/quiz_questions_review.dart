import 'package:animated_button/animated_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/new_quiz_provider.dart';
import 'package:ui_quiz/screens/quiz/quiz_play.dart';

class QuizQuestionsReviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;

  const QuizQuestionsReviewScreen({super.key, required this.questions});

  @override
  State<QuizQuestionsReviewScreen> createState() =>
      _QuizQuestionsReviewScreenState();
}

class _QuizQuestionsReviewScreenState extends State<QuizQuestionsReviewScreen>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _questions;
  late final ScrollController _scrollController;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions);
    _scrollController = ScrollController();

    // Ensure the number of questions is increased
    while (_questions.length < 3) {
      _questions.addAll(widget.questions);
    }
    _questions = _questions.take(30).toList();
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _questions.length) return;

    // Capture the text to show during the removal animation
    final removedText = (_questions[index]['question'] ?? '').toString();

    // Remove from the backing list
    _questions.removeAt(index);

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axis: Axis.vertical,
          child: Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey, width: 2),
            ),
            child: Text(
              removedText,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: Colors.grey[800],
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showExitConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Discard Quiz?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'If you go back now, all progress will be lost and the quiz will not be saved.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    // small left padding instead of large top gap
                    Padding(padding: const EdgeInsets.only(left: 20, top: 80)),
                    GestureDetector(
                      onTap: () => _showExitConfirmation(),
                      child: AnimatedButton(
                        onPressed: () => _showExitConfirmation(),
                        color: Colors.grey,
                        enabled: true,
                        disabledColor: Colors.grey,
                        shadowDegree: ShadowDegree.light,
                        borderRadius: 8,
                        duration: 0,
                        height: 40,
                        width: 40,
                        child: const Icon(
                          CupertinoIcons.clear,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 22.0),
                      child: Text(
                        'Delete the questions you don\'t need.',
                        style: CupertinoTheme.of(context).textTheme.textStyle
                            .copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                              fontFamily: 'Nunito',
                            ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),

                // Sorular listesi (AnimatedList ile silme animasyonunu geri getiriyoruz)
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    thickness: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        36, // left
                        0, // top - move questions slightly up
                        36, // right
                        100, // bottom - leave space for Continue button
                      ),
                      child: AnimatedList(
                        key: _listKey,
                        initialItemCount: _questions.length,
                        itemBuilder: (context, index, animation) {
                          final question = _questions[index];

                          Widget listItem = Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 30,
                                      ),
                                      height: 40,
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        '${index + 1}',
                                        style: CupertinoTheme.of(context)
                                            .textTheme
                                            .textStyle
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              fontFamily: 'Nunito',
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 2,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            question['question'],
                                            style: CupertinoTheme.of(context)
                                                .textTheme
                                                .textStyle
                                                .copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.3,
                                                  color: Colors.grey[800],
                                                  fontFamily: 'Nunito',
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _removeItem(index),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 15.0,
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.delete,
                                          color: CupertinoColors.destructiveRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );

                          return SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.vertical,
                            child: listItem,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Continue button
            Positioned(
              bottom: 20,
              right: 20,

              child: AnimatedButton(
                onPressed: () {
                  final provider = Provider.of<NewQuizProvider>(
                    context,
                    listen: false,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QuizPlayScreen(
                        questions: _questions,
                        quizTitle: provider.currentQuizTitle.isNotEmpty
                            ? provider.currentQuizTitle
                            : 'Quiz',
                      ),
                    ),
                  );
                },
                color: Colors.lime,
                enabled: true,
                disabledColor: Colors.grey,
                shadowDegree: ShadowDegree.light,
                borderRadius: 20,
                duration: 0,
                height: 70,
                width: 350,
                child: Text(
                  'Continue',
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Nunito',
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
