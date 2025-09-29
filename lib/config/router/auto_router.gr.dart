// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i4;
import 'package:ui_quiz/screens/home_screen.dart' as _i1;
import 'package:ui_quiz/screens/quiz_generator.dart' as _i2;
import 'package:ui_quiz/screens/quiz_play.dart' as _i3;

abstract class $AppRouter extends _i4.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i4.PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i1.HomeScreen(),
      );
    },
    QuizGeneratorRoute.name: (routeData) {
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.QuizGeneratorScreen(),
      );
    },
    QuizPlayRoute.name: (routeData) {
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.QuizPlayScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.HomeScreen]
class HomeRoute extends _i4.PageRouteInfo<void> {
  const HomeRoute({List<_i4.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i4.PageInfo<void> page = _i4.PageInfo<void>(name);
}

/// generated route for
/// [_i2.QuizGeneratorScreen]
class QuizGeneratorRoute extends _i4.PageRouteInfo<void> {
  const QuizGeneratorRoute({List<_i4.PageRouteInfo>? children})
      : super(
          QuizGeneratorRoute.name,
          initialChildren: children,
        );

  static const String name = 'QuizGeneratorRoute';

  static const _i4.PageInfo<void> page = _i4.PageInfo<void>(name);
}

/// generated route for
/// [_i3.QuizPlayScreen]
class QuizPlayRoute extends _i4.PageRouteInfo<void> {
  const QuizPlayRoute({List<_i4.PageRouteInfo>? children})
      : super(
          QuizPlayRoute.name,
          initialChildren: children,
        );

  static const String name = 'QuizPlayRoute';

  static const _i4.PageInfo<void> page = _i4.PageInfo<void>(name);
}
