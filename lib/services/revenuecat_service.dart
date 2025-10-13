import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RevenueCatService {
  // Replace with your RevenueCat public API key
  static const String _publicKey = 'REVENUECAT_PUBLIC_API_KEY';

  static Future<void> init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await Purchases.setDebugLogsEnabled(true);
    try {
      // primary API
      await Purchases.setup(_publicKey, appUserId: uid);
      return;
    } catch (e) {
      print('Purchases.setup failed: $e');
    }

    print('RevenueCat: initialized (or attempted) Purchases SDK');
    print(
      'RevenueCat: could not initialize Purchases SDK with provided methods',
    );
  }

  // Try multiple method names that changed across versions
  static Future<dynamic> _fetchPurchaserInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      print('Error getting customer info: $e');
      return null;
    }
  }

  static Future<dynamic> getPurchaserInfo() async {
    return await _fetchPurchaserInfo();
  }

  static bool _extractIsPremiumFromInfo(dynamic info) {
    if (info == null) return false;
    try {
      final ent = info.entitlements;
      if (ent != null) {
        try {
          final allMap = ent.all;
          if (allMap != null && allMap['premium'] != null) {
            return allMap['premium']?.isActive ?? false;
          }
        } catch (_) {}

        try {
          if (ent['premium'] != null) return ent['premium']?.isActive ?? false;
        } catch (_) {}
      }
    } catch (_) {}

    try {
      // older/newer property
      final activeSubs = info.activeSubscriptions;
      if (activeSubs is List && activeSubs.isNotEmpty) return true;
    } catch (_) {}

    return false;
  }

  static Future<bool> isPremium() async {
    final info = await getPurchaserInfo();
    return _extractIsPremiumFromInfo(info);
  }

  static Future<void> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
    } catch (e) {
      // rethrow so UI can show error
      rethrow;
    }
  }
}
