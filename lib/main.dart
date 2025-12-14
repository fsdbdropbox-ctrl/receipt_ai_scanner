import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:receipt_ai_scanner/features/scan/scan_view.dart';
import 'package:receipt_ai_scanner/features/scan/scan_view_model.dart';
import 'package:receipt_ai_scanner/core/auth/installation_id_service.dart';
import 'package:receipt_ai_scanner/core/payments/entitlement_service.dart';
import 'package:receipt_ai_scanner/shared/utils/constants.dart';

void main() async {
  final sentryDsn = AppConstants.sentryDsn;
  
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.1;
        options.environment = AppConstants.environment;
      },
      appRunner: () => runApp(const ReceiptScannerApp()),
    );
  } else {
    runApp(const ReceiptScannerApp());
  }
}

class ReceiptScannerApp extends StatelessWidget {
  const ReceiptScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ScanViewModel(
            installationIdService: InstallationIdService(),
            entitlementService: EntitlementService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Receipt AI Scanner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'SF Pro Display',
        ),
        home: const ScanView(),
      ),
    );
  }
}

