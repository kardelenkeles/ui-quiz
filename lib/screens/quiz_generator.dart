import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ui_quiz/screens/home_screen.dart';
import 'package:ui_quiz/screens/profile_screen.dart';

class QuizGeneratorScreen extends StatefulWidget {
  const QuizGeneratorScreen({super.key});

  @override
  State<QuizGeneratorScreen> createState() => _QuizGeneratorScreenState();
}

class _QuizGeneratorScreenState extends State<QuizGeneratorScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const QuizGeneratorContent(),
    const HomeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: FlashyTabBar(
        selectedIndex: _selectedIndex,
        showElevation: true,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
        items: [
          FlashyTabBarItem(
            icon: const Icon(CupertinoIcons.sparkles),
            title: const Text('Generate'),
            activeColor: Colors.lime,
          ),
          FlashyTabBarItem(
            icon: const Icon(CupertinoIcons.list_bullet),
            title: const Text('Liste'),
            activeColor: Colors.lime,
          ),
          FlashyTabBarItem(
            icon: const Icon(CupertinoIcons.person),
            title: const Text('Profil'),
            activeColor: Colors.lime,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // no PageController now
    super.dispose();
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
    if (_textController.text.length < 30) {
      _showAlert('Uyarı', 'Lütfen en az 30 karakter girin');
      return;
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
                alignment: Alignment.center,
                child: CupertinoTextField(
                  controller: _textController,
                  maxLines: null,
                  placeholder: 'Metni buraya yapıştırın...',
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            Align(
              alignment: const Alignment(0.5, 0.8),
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
