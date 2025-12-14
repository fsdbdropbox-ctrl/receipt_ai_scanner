import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:receipt_ai_scanner/features/home/home_shell.dart';
import 'package:receipt_ai_scanner/features/scan/scan_view_model.dart';
import 'package:receipt_ai_scanner/core/auth/installation_id_service.dart';
import 'package:receipt_ai_scanner/core/payments/entitlement_service.dart';
import 'package:receipt_ai_scanner/core/locale/locale_provider.dart';
import 'package:receipt_ai_scanner/core/quota/quota_provider.dart';
import 'package:receipt_ai_scanner/shared/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize locale provider
  final localeProvider = LocaleProvider();
  await localeProvider.initialize();
  
  final sentryDsn = AppConstants.sentryDsn;
  
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.1;
        options.environment = AppConstants.environment;
      },
      appRunner: () => runApp(ReceiptDataApp(localeProvider: localeProvider)),
    );
  } else {
    runApp(ReceiptDataApp(localeProvider: localeProvider));
  }
}

class ReceiptDataApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  
  const ReceiptDataApp({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(
          create: (_) => ScanViewModel(
            installationIdService: InstallationIdService(),
            entitlementService: EntitlementService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => QuotaProvider()..refreshQuota(),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            // Locale configuration - use currentLocale which never returns null
            locale: localeProvider.currentLocale,
            supportedLocales: LocaleProvider.supportedLocales,
            localeResolutionCallback: LocaleProvider.localeResolutionCallback,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2563EB),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              fontFamily: 'SF Pro Display',
            ),
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}

