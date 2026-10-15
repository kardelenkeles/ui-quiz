import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_quiz/screens/onboarding/paywall_screen.dart';
import 'package:ui_quiz/services/purchase_service.dart';

class _RecordingGateway implements PurchaseGateway {
  String? plan;

  @override
  Future<bool> purchasePlan(String plan) async {
    this.plan = plan;
    return false;
  }
}

void main() {
  testWidgets('selects and submits the weekly purchase plan', (tester) async {
    final gateway = _RecordingGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: PaywallScreen(purchaseService: PurchaseService(gateway: gateway)),
      ),
    );

    await tester.ensureVisible(find.text('Weekly Plan'));
    await tester.pump();
    await tester.tap(find.text('Weekly Plan'));
    await tester.pump();
    expect(find.text('Subscribe Weekly Plan'), findsOneWidget);

    await tester.ensureVisible(find.text('Subscribe Weekly Plan'));
    await tester.tap(find.text('Subscribe Weekly Plan'));
    await tester.pump();
    expect(gateway.plan, 'weekly');

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
