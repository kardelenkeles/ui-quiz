import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/config/app_config.dart';
import 'package:ui_quiz/firebase_options.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';
import 'providers/quiz_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/new_quiz_provider.dart';
import 'services/service_locator.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppConfig.initialize();

  // .env dosyasından API key'i al
  final openAIApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  print('OpenAI API Key loaded: ${openAIApiKey.isNotEmpty ? "✓" : "✗"}');

  services.initialize(openAIApiKey: openAIApiKey);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      gestures: const [GestureType.onTap],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => QuizProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => NewQuizProvider()),
        ],
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                scaffoldBackgroundColor: Colors.white,
                canvasColor: Colors.white,
                fontFamily: 'Nunito',
                textTheme: ThemeData.light().textTheme.copyWith(
                  titleLarge: TextStyle(fontFamily: 'Nunito'),
                  bodyLarge: TextStyle(fontFamily: 'Nunito'),
                  bodyMedium: TextStyle(fontFamily: 'Nunito'),
                  labelLarge: TextStyle(fontFamily: 'Nunito'),
                ),
              ),
              home: const CustomTabBarWidget(),
            );
          },
        ),
      ),
    );
  }
}
