import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppConfig.initialize();

  // Initialize services with an empty API key; we'll fetch it after auth.
  services.initialize(openAIApiKey: '');

  // When a user signs in, fetch a fresh ID token and request the API key
  // from the Cloud Function, then update the service locator.
  fb_auth.FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      try {
        final idToken = await user.getIdToken();
        // Replace with your function URL
        final url = Uri.parse(
          'https://us-central1-your-project.cloudfunctions.net/api/get-api-key',
        );
        final resp = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Accept': 'application/json',
          },
        );
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          final apiKey = body['apiKey'] as String? ?? '';
          if (apiKey.isNotEmpty) {
            services.updateOpenAIApiKey(apiKey);
          }
        } else {
          print('Failed to fetch API key: ${resp.statusCode} ${resp.body}');
        }
      } catch (e) {
        print('Error fetching API key: $e');
      }
    } else {
      // signed out: clear API key from services
      services.updateOpenAIApiKey('');
    }
  });

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
