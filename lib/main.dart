import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// No client-side API key fetch; OpenAI calls are proxied via Cloud Functions.
import 'package:provider/provider.dart';
import 'package:ui_quiz/config/app_config.dart';
import 'package:ui_quiz/firebase_options.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';
import 'package:ui_quiz/screens/onboarding/onboarding_welcome_screen.dart';
import 'providers/quiz_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/new_quiz_provider.dart';
import 'services/service_locator.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppConfig.initialize();

  // Initialize services with an empty API key; we'll fetch it after auth.
  services.initialize(openAIApiKey: '');

  // RevenueCat'i başlat
  await _configureRevenueCat();

  // We proxy all OpenAI calls via Cloud Functions in production.

  runApp(MyApp());
}

Future<void> _configureRevenueCat() async {
  // TODO: RevenueCat API anahtarlarınızı buraya ekleyin
  // https://app.revenuecat.com/overview adresinden alabilirsiniz

  if (Platform.isAndroid) {
    await Purchases.configure(
      PurchasesConfiguration('your_android_api_key_here'),
    );
  } else if (Platform.isIOS) {
    await Purchases.configure(PurchasesConfiguration('your_ios_api_key_here'));
  }

  // Debug mod aktif (geliştirme sırasında)
  await Purchases.setLogLevel(LogLevel.debug);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _getHomeScreen(AuthProvider auth) {
    // Eğer kullanıcı giriş yapmışsa ana ekrana git
    if (auth.user != null) {
      return const CustomTabBarWidget();
    }

    // Eğer giriş yapılmamışsa onboarding'e git
    return const OnboardingWelcomeScreen();
  }

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
              home: _getHomeScreen(auth),
            );
          },
        ),
      ),
    );
  }
}
