import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:receipt_ai_scanner/features/home/home_shell.dart';
import 'package:receipt_ai_scanner/features/scan/scan_view_model.dart';
import 'package:receipt_ai_scanner/core/auth/installation_id_service.dart';
import 'package:receipt_ai_scanner/core/payments/entitlement_service.dart';
import 'package:receipt_ai_scanner/core/locale/locale_provider.dart';
import 'package:receipt_ai_scanner/core/quota/quota_provider.dart';

/// Helper to create a testable app with proper localization
Widget createTestApp({Locale locale = const Locale('en')}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(
        create: (_) => ScanViewModel(
          installationIdService: InstallationIdService(),
          entitlementService: EntitlementService(),
        ),
      ),
      ChangeNotifierProvider(create: (_) => QuotaProvider()),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MediaQuery(
        // Use a large screen size to avoid overflow issues in tests
        data: MediaQueryData(size: Size(800, 1200)),
        child: HomeShell(),
      ),
    ),
  );
}

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Use a larger screen size to avoid overflow
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    
    await tester.pumpWidget(createTestApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify the app renders without crashing
    expect(find.byType(Scaffold), findsWidgets);
    
    // Reset view size
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
