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

  void _importFile() {
    // Gelecekte dosya seçme işlevi burada implement edilecek
    _showAlert('Bilgi', 'Dosya import özelliği yakında eklenecek!');
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
      resizeToAvoidBottomInset: true, // Klavye için otomatik ayarlama
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 30, left: 30),
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'asset/icon/pomegranate.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'pomeAI quiz',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ana içerik - Scrollable
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40), // Üstten boşluk
                      Image.asset(
                        'asset/icon/pastehere.png',
                        width: 180,
                        height: 180,
                      ),
                      const SizedBox(height: 10),
                      CupertinoTextField(
                        controller: _textController,
                        maxLines: 10,
                        expands: false,
                        minLines: 6,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(4, 4),
                            ),
                            BoxShadow(
                              color: Colors.white,
                              blurRadius: 10,
                              offset: Offset(-4, -4),
                            ),
                          ],
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                            width: 1.5,
                          ),
                        ),
                        scrollController: ScrollController(),
                      ),
                      const SizedBox(height: 100),

                      // Import butonu - daraltılmış ve ortalanmış
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CupertinoButton(
                            onPressed: _importFile,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 64,
                              vertical: 32,
                            ),
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'asset/icon/file-import.png',
                                  width: 30,
                                  height: 30,
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Generate butonu da scrollable içinde
                      Align(
                        alignment: Alignment.centerRight,
                        child: CupertinoButton.filled(
                          onPressed: _generateQuiz,
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.lime,
                          child: const Text('Generate'),
                        ),
                      ),
                      const SizedBox(height: 40), // Alttan boşluk
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
