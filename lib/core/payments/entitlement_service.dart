import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:receipt_ai_scanner/core/payments/entitlement_service_web.dart';

// Conditional imports - only import IO service on mobile platforms
import 'entitlement_service_stub.dart'
    if (dart.library.io) 'entitlement_service_io.dart';

abstract class EntitlementService {
  Future<bool> isPremium();
  Future<void> initialize();
  
  factory EntitlementService() {
    if (kIsWeb) {
      return WebEntitlementService();
    }
    // For mobile platforms (iOS/Android), use IO service
    // On web, this will use StubEntitlementService (which returns false)
    return IoEntitlementService();
  }
}

