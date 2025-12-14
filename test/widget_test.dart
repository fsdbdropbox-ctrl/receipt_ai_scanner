import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_ai_scanner/main.dart';

void main() {
  testWidgets('Receipt scanner app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ReceiptScannerApp());
    await tester.pumpAndSettle();

    // Verify that the app title is present
    expect(find.text('Receipt AI Scanner'), findsOneWidget);

    // Verify that the bottom navigation is present
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // Verify that the scan action buttons are present
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('From gallery'), findsOneWidget);
    expect(find.text('Select file'), findsOneWidget);
  });

  testWidgets('Can navigate to history tab', (WidgetTester tester) async {
    await tester.pumpWidget(const ReceiptScannerApp());
    await tester.pumpAndSettle();

    // Tap on History tab
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    // Verify history view is shown
    expect(find.text('History'), findsWidgets);
  });

  testWidgets('Can navigate back to scan tab from history', (WidgetTester tester) async {
    await tester.pumpWidget(const ReceiptScannerApp());
    await tester.pumpAndSettle();

    // Go to History
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    // Go back to Scan
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    // Verify scan view is shown again
    expect(find.text('Receipt AI Scanner'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
  });
}
