import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_ai_scanner/features/scan/scan_view_model.dart';
import 'package:receipt_ai_scanner/core/auth/installation_id_service.dart';
import 'package:receipt_ai_scanner/core/payments/entitlement_service.dart';

void main() {
  group('ScanViewModel', () {
    late InstallationIdService installationIdService;
    late EntitlementService entitlementService;
    late ScanViewModel viewModel;

    setUp(() {
      installationIdService = InstallationIdService();
      entitlementService = EntitlementService();
      viewModel = ScanViewModel(
        installationIdService: installationIdService,
        entitlementService: entitlementService,
      );
    });

    test('should initialize in idle state', () {
      expect(viewModel.state, ScanState.idle);
      expect(viewModel.scanResult, isNull);
      expect(viewModel.error, isNull);
    });

    test('should reset to idle state', () {
      viewModel.reset();
      
      expect(viewModel.state, ScanState.idle);
      expect(viewModel.scanResult, isNull);
      expect(viewModel.error, isNull);
      expect(viewModel.imageBytes, isNull);
    });

    // Note: Full scanImage tests would require mocking InvoiceScannerService
    // This covers the basic state management
  });
}

