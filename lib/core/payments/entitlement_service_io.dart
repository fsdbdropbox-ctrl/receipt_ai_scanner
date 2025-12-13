import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:receipt_ai_scanner/core/payments/entitlement_service.dart';

class IoEntitlementService implements EntitlementService {
  @override
  Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active['premium'] != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> initialize() async {
    // Initialize RevenueCat
    // await Purchases.configure(/* config */);
  }
}

