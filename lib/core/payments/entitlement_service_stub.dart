import 'package:receipt_ai_scanner/core/payments/entitlement_service.dart';

class StubEntitlementService implements EntitlementService {
  @override
  Future<bool> isPremium() async => false;

  @override
  Future<void> initialize() async {}
}

