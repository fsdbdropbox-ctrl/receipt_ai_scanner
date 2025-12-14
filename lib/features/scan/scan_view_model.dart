import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:receipt_ai_scanner/core/ai/invoice_scanner_service.dart';
import 'package:receipt_ai_scanner/core/auth/installation_id_service.dart';
import 'package:receipt_ai_scanner/core/payments/entitlement_service.dart';
import 'package:receipt_ai_scanner/shared/models/scan_invoice_response.dart';
import 'package:receipt_ai_scanner/core/errors/scan_error.dart';

enum ScanState {
  idle,
  scanning,
  success,
  error,
}

class ScanViewModel extends ChangeNotifier {
  // ignore: unused_field - kept for future use (premium checks, etc.)
  final InstallationIdService _installationIdService;
  // ignore: unused_field - kept for future use (entitlement checks)
  final EntitlementService _entitlementService;
  final InvoiceScannerService _scannerService;

  ScanState _state = ScanState.idle;
  Uint8List? _imageBytes;
  ScanInvoiceResponse? _scanResult;
  ScanError? _error;

  ScanViewModel({
    required InstallationIdService installationIdService,
    required EntitlementService entitlementService,
    InvoiceScannerService? scannerService,
  })  : _installationIdService = installationIdService,
        _entitlementService = entitlementService,
        _scannerService = scannerService ??
            InvoiceScannerService(installationIdService: installationIdService);

  ScanState get state => _state;
  Uint8List? get imageBytes => _imageBytes;
  ScanInvoiceResponse? get scanResult => _scanResult;
  ScanError? get error => _error;

  Future<void> scanImage(Uint8List imageBytes, String locale) async {
    _imageBytes = imageBytes;
    _state = ScanState.scanning;
    _error = null;
    notifyListeners();

    try {
      final result = await _scannerService.scanInvoice(imageBytes, locale);
      _scanResult = result;
      _state = ScanState.success;
    } on ScanError catch (e) {
      _error = e;
      _state = ScanState.error;
      // Report to Sentry
      await Sentry.captureException(
        e,
        withScope: (scope) {
          scope.setTag('error_type', 'scan_error');
          scope.setTag('error_code', e.code.toString());
          scope.setContexts('scan', {
            'locale': locale,
            'imageSize': imageBytes.length,
          });
        },
      );
    } catch (e, stackTrace) {
      _error = ScanError(
        code: ScanErrorCode.unknown,
        message: e.toString(),
      );
      _state = ScanState.error;
      // Report unexpected errors to Sentry
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_type', 'unexpected_error');
          scope.setContexts('scan', {
            'locale': locale,
            'imageSize': imageBytes.length,
          });
        },
      );
    }
    notifyListeners();
  }

  void reset() {
    _state = ScanState.idle;
    _imageBytes = null;
    _scanResult = null;
    _error = null;
    notifyListeners();
  }
}

