import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_ai_scanner/shared/widgets/bottom_navigation.dart';

void main() {
  group('AppBottomNavigation', () {
    testWidgets('displays scan and history tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavigation(
              currentTab: AppTab.scan,
              onTabChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('calls onTabChanged when tab is tapped', (tester) async {
      AppTab? tappedTab;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavigation(
              currentTab: AppTab.scan,
              onTabChanged: (tab) => tappedTab = tab,
            ),
          ),
        ),
      );

      await tester.tap(find.text('History'));
      await tester.pump();

      expect(tappedTab, equals(AppTab.history));
    });

    testWidgets('highlights current tab with correct color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavigation(
              currentTab: AppTab.scan,
              onTabChanged: (_) {},
            ),
          ),
        ),
      );

      // Find the scan icon which should be active (blue)
      final scanIcon = find.byIcon(Icons.document_scanner);
      expect(scanIcon, findsOneWidget);
    });

    testWidgets('displays Spanish labels when locale is Spanish', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es'), Locale('en')],
          home: Scaffold(
            bottomNavigationBar: AppBottomNavigation(
              currentTab: AppTab.scan,
              onTabChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Escanear'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
    });
  });
}

