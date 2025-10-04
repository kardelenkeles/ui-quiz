import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:transformable_list_view/transformable_list_view.dart';

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

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions);

    // Ensure the number of questions is increased
    while (_questions.length < 30) {
      _questions.addAll(widget.questions);
    }
    _questions = _questions.take(30).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        middle: Text(
          'Soruları İncele',
          style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Sorular listesi
            Expanded(
              child: TransformableListView.builder(
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

                  if (item.position != TransformableListItemPosition.middle) {
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
                                  width: 20,
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
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.limeAccent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: CupertinoColors.systemGrey4,
                                    width: 1,
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
                                    padding: const EdgeInsets.only(left: 15.0),
                                    child: Icon(
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
