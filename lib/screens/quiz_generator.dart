import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ui_quiz/screens/quiz_play.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';

// Ana QuizGeneratorScreen artık sadece CustomTabBarWidget'ı çağırıyor
class QuizGeneratorScreen extends StatelessWidget {
  const QuizGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomTabBarWidget();
  }
}

class QuizGeneratorContent extends StatefulWidget {
  const QuizGeneratorContent({super.key});

  @override
  State<QuizGeneratorContent> createState() => _QuizGeneratorContentState();
}

class _QuizGeneratorContentState extends State<QuizGeneratorContent> {
  final _textController = TextEditingController();

  void _generateQuiz() {
    // if (_textController.text.length < 30) {
    //   _showAlert('Uyarı', 'Lütfen en az 30 karakter girin');
    //   return;
    // }

    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (context) => const QuizPlayScreen()));
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Align(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'asset/icon/pastehere.png',
                        width: 200,
                        height: 200,
                      ),
                      const SizedBox(height: 5),
                      CupertinoTextField(
                        controller: _textController,
                        maxLines: 10,
                        expands: false,
                        minLines: 4,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        scrollController: ScrollController(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0.8, 0.2),
              child: CupertinoButton.filled(
                onPressed: _generateQuiz,
                borderRadius: BorderRadius.circular(20),
                color: Colors.lime,
                child: const Text('Generate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
