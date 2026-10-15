import 'package:flutter_test/flutter_test.dart';
import 'package:ui_quiz/services/purchase_service.dart';

class _FakePurchaseGateway implements PurchaseGateway {
  _FakePurchaseGateway(this.result);

  final bool result;
  String? purchasedPlan;

  @override
  Future<bool> purchasePlan(String plan) async {
    purchasedPlan = plan;
    return result;
  }
}

void main() {
  test(
    'purchase forwards a supported plan and returns entitlement state',
    () async {
      final gateway = _FakePurchaseGateway(true);
      final service = PurchaseService(gateway: gateway);

      expect(await service.purchase('annual'), isTrue);
      expect(gateway.purchasedPlan, 'annual');
    },
  );

  test('purchase rejects unknown plans before calling the gateway', () async {
    final gateway = _FakePurchaseGateway(true);
    final service = PurchaseService(gateway: gateway);

    expect(() => service.purchase('lifetime'), throwsArgumentError);
    expect(gateway.purchasedPlan, isNull);
  });
}
