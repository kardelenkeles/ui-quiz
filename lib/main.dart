import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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
import 'services/email_link_service.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:ui_quiz/core/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _configureErrorReporting();
  await AppConfig.initialize();
  await EmailLinkService.instance.initialize();

  services.initialize();

  // RevenueCat'i başlat
  await _configureRevenueCat();

  // We proxy all OpenAI calls via Cloud Functions in production.

  runApp(MyApp());
}

Future<void> _configureRevenueCat() async {
  String? apiKey;
  String? platform;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    apiKey = AppConfig.revenueCatAndroidApiKey;
    platform = 'android';
  } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    apiKey = AppConfig.revenueCatIosApiKey;
    platform = 'ios';
  } else {
    return;
  }

  AppConfig.validateRevenueCatKey(platform: platform, apiKey: apiKey);
  if (apiKey.isEmpty) {
    AppLogger.warning(
      'RevenueCat is disabled: $platform SDK key is not configured.',
    );
    return;
  }

  await Purchases.setLogLevel(
    AppConfig.isProduction ? LogLevel.error : LogLevel.debug,
  );
  await Purchases.configure(PurchasesConfiguration(apiKey));
  AppConfig.revenueCatConfigured = true;
}

void _configureErrorReporting() {
  final supportsCrashlytics =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (!supportsCrashlytics) return;

  AppLogger.configure(
    errorReporter: (error, stackTrace, {required fatal, reason}) =>
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: fatal,
          reason: reason,
        ),
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.error(error, stackTrace: stackTrace, fatal: true);
    return true;
  };
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
