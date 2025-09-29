import 'package:auto_route/auto_route.dart';
import 'package:ui_quiz/config/router/auto_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeScreen.page),
    AutoRoute(page: AuthPage.page, initial: true),
    AutoRoute(page: QuizPlayScreen.page),
    AutoRoute(page: QuizGeneratorScreen.page),
  ];
}
