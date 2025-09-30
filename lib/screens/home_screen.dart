import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_quiz/screens/quiz_generator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGrey6,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [const SizedBox(height: 40)],
          ),
        ),
      ),
    );
  }
}
