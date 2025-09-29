import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/screens/quiz_generator.dart';
import 'package:ui_quiz/screens/quiz_play.dart';
import 'package:ui_quiz/screens/quiz_result.dart';
import 'providers/quiz_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => QuizProvider(),
      child: MaterialApp(
        title: 'QuizAI',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
        routes: {
          '/generator': (context) => const QuizGeneratorScreen(),
          '/play': (context) => const QuizPlayScreen(),
          '/result': (context) => const QuizResultScreen(),
        },
      ),
    );
  }
}
