import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:ui_quiz/config/app_config.dart';

abstract interface class PurchaseGateway {
  Future<bool> purchasePlan(String plan);
}

class RevenueCatPurchaseGateway implements PurchaseGateway {
  @override
  Future<bool> purchasePlan(String plan) async {
    if (!AppConfig.revenueCatConfigured) {
      throw StateError(
        'Payments are not available until RevenueCat is configured.',
      );
    }
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) throw StateError('No offerings available');

    final package = switch (plan) {
      'annual' => current.annual,
      'weekly' => current.weekly,
      _ => throw ArgumentError.value(plan, 'plan', 'Unsupported plan'),
    };
    if (package == null) throw StateError('Selected plan not available');

    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo.entitlements.all['pro']?.isActive == true;
  }
}

class PurchaseService {
  PurchaseService({PurchaseGateway? gateway})
    : _gateway = gateway ?? RevenueCatPurchaseGateway();

  final PurchaseGateway _gateway;

  Future<bool> purchase(String plan) {
    if (plan != 'annual' && plan != 'weekly') {
      throw ArgumentError.value(plan, 'plan', 'Unsupported plan');
    }
    return _gateway.purchasePlan(plan);
  }
}
