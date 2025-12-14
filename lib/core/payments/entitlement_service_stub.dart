import 'package:receipt_ai_scanner/core/payments/entitlement_service.dart';

// This is used as a stub when dart.library.io is not available (web)
class IoEntitlementService implements EntitlementService {
  @override
  Future<bool> isPremium() async => false;

  @override
  Future<void> initialize() async {}
}

