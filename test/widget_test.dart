import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_ai_scanner/main.dart';
import 'package:receipt_ai_scanner/core/locale/locale_provider.dart';

void main() {
  testWidgets('ReceiptData app smoke test', (WidgetTester tester) async {
    // Create a mock locale provider
    final localeProvider = LocaleProvider();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(ReceiptDataApp(localeProvider: localeProvider));
    await tester.pumpAndSettle();

    // Verify that the app title is present
    expect(find.text('ReceiptData'), findsOneWidget);

    // Verify that the bottom navigation is present
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('Can navigate to history tab', (WidgetTester tester) async {
    final localeProvider = LocaleProvider();
    
    await tester.pumpWidget(ReceiptDataApp(localeProvider: localeProvider));
    await tester.pumpAndSettle();

    // Tap on History tab
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    // Verify history view is shown (History appears in both nav and title)
    expect(find.text('History'), findsWidgets);
  });

  testWidgets('Can navigate back to scan tab from history', (WidgetTester tester) async {
    final localeProvider = LocaleProvider();
    
    await tester.pumpWidget(ReceiptDataApp(localeProvider: localeProvider));
    await tester.pumpAndSettle();

    // Go to History
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    // Go back to Scan
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    // Verify scan view is shown again
    expect(find.text('ReceiptData'), findsOneWidget);
  });
}
