import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:receipt_ai_scanner/core/payments/entitlement_service_stub.dart'
    if (dart.library.io) 'package:receipt_ai_scanner/core/payments/entitlement_service_io.dart'
    if (dart.library.html) 'package:receipt_ai_scanner/core/payments/entitlement_service_web.dart';

abstract class EntitlementService {
  Future<bool> isPremium();
  Future<void> initialize();
  
  factory EntitlementService() {
    if (kIsWeb) {
      return WebEntitlementService();
    } else if (Platform.isIOS || Platform.isAndroid) {
      return IoEntitlementService();
    }
    return StubEntitlementService();
  }
}

