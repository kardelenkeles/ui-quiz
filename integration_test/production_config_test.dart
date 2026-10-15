import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ui_quiz/config/app_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('production endpoints are HTTPS and never localhost', (_) async {
    await AppConfig.initialize();

    expect(Uri.parse(AppConfig.apiBaseUrl).scheme, 'https');
    expect(Uri.parse(AppConfig.authContinueUrl).scheme, 'https');
    expect(AppConfig.apiBaseUrl, isNot(contains('localhost')));
    expect(AppConfig.authContinueUrl, isNot(contains('localhost')));
  });
}
