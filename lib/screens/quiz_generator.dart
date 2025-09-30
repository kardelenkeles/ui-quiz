import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';
import 'package:ui_quiz/screens/quiz_play.dart';
import '../providers/quiz_provider.dart';

class QuizGeneratorScreen extends StatefulWidget {
  const QuizGeneratorScreen({super.key});

  @override
  State<QuizGeneratorScreen> createState() => _QuizGeneratorScreenState();
}

class _QuizGeneratorScreenState extends State<QuizGeneratorScreen> {
  final _textController = TextEditingController();

  void _generateQuiz() async {
    if (_textController.text.length < 30) {
      _showAlert('Uyarı', 'Lütfen en az 30 karakter girin');
      return;
    }

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    await quizProvider.generateQuiz(_textController.text);

    if (quizProvider.error.isNotEmpty) {
      _showAlert('Hata', quizProvider.error);
    } else if (quizProvider.currentQuiz != null) {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (context) => const QuizPlayScreen()));
    }
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
            child: const Text('Tamam'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.create),
            label: 'Generate',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.time),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_2),
            label: 'Subscription',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        if (index == 0) {
          return CupertinoPageScaffold(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Consumer<QuizProvider>(
                  builder: (context, quizProvider, child) {
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                // Fixed height multi-line field
                                SizedBox(
                                  height: 200,
                                  child: CupertinoTextField(
                                    controller: _textController,
                                    maxLines: 8,
                                    placeholder: 'Metni buraya yapıştırın...',
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Spacer(),
                                    if (_textController.text.isNotEmpty)
                                      CupertinoButton(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        onPressed: () {
                                          _textController.clear();
                                          setState(() {});
                                        },
                                        child: const Text('Temizle'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 120,
                          height: 50,
                          child: CupertinoButton.filled(
                            onPressed: quizProvider.isLoading
                                ? null
                                : _generateQuiz,
                            child: quizProvider.isLoading
                                ? const CupertinoActivityIndicator()
                                : const Text('Generate'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        }

        if (index == 1) {
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('History'),
            ),
            child: const SafeArea(
              child: Center(
                child: Text('History - geçmiş quizler burada gösterilecek'),
              ),
            ),
          );
        }

        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(middle: Text('Abonelik')),
          child: SafeArea(
            child: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Subscription - abonelik seçenekleri burada'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: CupertinoButton.filled(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  try {
                                    await auth.signOut();
                                  } catch (e) {
                                    _showAlert('Hata', 'Çıkış hatası: $e');
                                  }
                                },
                          color: CupertinoColors.systemRed,
                          child: auth.isLoading
                              ? const CupertinoActivityIndicator()
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.power),
                                    SizedBox(width: 8),
                                    Text('Çıkış Yap'),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
