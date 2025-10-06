import 'package:animated_button/animated_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:transformable_list_view/transformable_list_view.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                    Padding(padding: const EdgeInsets.only(left: 20, top: 100)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: AnimatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        color: Colors.grey,
                        enabled: true,
                        disabledColor: Colors.grey,
                        shadowDegree: ShadowDegree.light,
                        borderRadius: 8,
                        duration: 0,
                        height: 40,
                        width: 40,
                        child: const Icon(
                          CupertinoIcons.back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // Instruction text
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Delete the questions you don\'t need.',
                    style: CupertinoTheme.of(context).textTheme.textStyle
                        .copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.secondaryLabel,
                          fontFamily: 'Nunito',
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Sorular listesi
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    thickness: 4,
                    child: TransformableListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 20,
                      ),
                      itemCount: _questions.length,
                      getTransformMatrix: (item) {
                        const endScaleBound = 0.3;
                        final animationProgress =
                            item.visibleExtent / item.size.height;
                        final paintTransform = Matrix4.identity();

                        if (item.position !=
                            TransformableListItemPosition.middle) {
                          final scale =
                              endScaleBound +
                              ((1 - endScaleBound) * animationProgress);

                          paintTransform
                            ..translate(item.size.width / 2)
                            ..scale(scale)
                            ..translate(-item.size.width / 2);
                        }

                        return paintTransform;
                      },
                      itemBuilder: (context, index) {
                        final question = _questions[index];
                        final isDeleted = ValueNotifier(false);

                        return ValueListenableBuilder<bool>(
                          valueListenable: isDeleted,
                          builder: (context, deleted, child) {
                            if (deleted) {
                              return Align(
                                alignment: Alignment.center,
                                child: Lottie.asset(
                                  'asset/animations/explode.json',
                                  width: 100,
                                  height: 100,
                                  repeat: false,
                                  onLoaded: (composition) {
                                    Future.delayed(composition.duration, () {
                                      setState(() {
                                        _questions.removeAt(index);
                                      });
                                    });
                                  },
                                ),
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 18),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
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
                                        onTap: () {
                                          isDeleted.value = true;
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 15.0,
                                          ),
                                          child: Icon(
                                            CupertinoIcons.delete,
                                            color:
                                                CupertinoColors.destructiveRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
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
                height: 60,
                width: 140,
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
