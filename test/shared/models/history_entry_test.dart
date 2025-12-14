import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_ai_scanner/shared/models/history_entry.dart';
import 'package:receipt_ai_scanner/shared/models/invoice_data.dart';

void main() {
  group('HistoryEntry', () {
    test('fromInvoiceData creates entry with correct values', () {
      final invoiceData = InvoiceData(
        date: DateTime(2024, 10, 15),
        total: 599.00,
        tax: 91.36,
        vendor: 'Test Vendor',
        category: InvoiceCategory.office,
        currency: 'USD',
        confidence: 0.95,
      );

      final entry = HistoryEntry.fromInvoiceData(invoiceData);

      expect(entry.id, isNotEmpty);
      expect(entry.scannedAt, isNotNull);
      expect(entry.invoiceDate, equals(DateTime(2024, 10, 15)));
      expect(entry.total, equals(599.00));
      expect(entry.tax, equals(91.36));
      expect(entry.vendor, equals('Test Vendor'));
      expect(entry.category, equals(InvoiceCategory.office));
      expect(entry.currency, equals('USD'));
      expect(entry.confidence, equals(0.95));
    });

    test('toJson and fromJson roundtrip preserves data', () {
      final original = HistoryEntry(
        id: '12345',
        scannedAt: DateTime(2024, 10, 15, 10, 30),
        invoiceDate: DateTime(2024, 10, 10),
        total: 250.50,
        tax: 40.08,
        vendor: 'Coffee Shop',
        category: InvoiceCategory.food,
        currency: 'EUR',
        confidence: 0.85,
      );

      final json = original.toJson();
      final restored = HistoryEntry.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.scannedAt, equals(original.scannedAt));
      expect(restored.invoiceDate, equals(original.invoiceDate));
      expect(restored.total, equals(original.total));
      expect(restored.tax, equals(original.tax));
      expect(restored.vendor, equals(original.vendor));
      expect(restored.category, equals(original.category));
      expect(restored.currency, equals(original.currency));
      expect(restored.confidence, equals(original.confidence));
    });

    test('toCsvRow formats correctly', () {
      final entry = HistoryEntry(
        id: '12345',
        scannedAt: DateTime(2024, 10, 15),
        invoiceDate: DateTime(2024, 10, 10),
        total: 100.00,
        tax: 16.00,
        vendor: 'Test Store',
        category: InvoiceCategory.retail,
        currency: 'USD',
        confidence: 0.9,
      );

      final csv = entry.toCsvRow();

      expect(csv, contains('2024-10-10'));
      expect(csv, contains('Test Store'));
      expect(csv, contains('100.00'));
      expect(csv, contains('16.00'));
      expect(csv, contains('USD'));
      expect(csv, contains('retail'));
    });

    test('getFormattedAmount returns correct format', () {
      final entry = HistoryEntry(
        id: '1',
        scannedAt: DateTime.now(),
        total: 150.99,
        currency: '\$',
        category: InvoiceCategory.other,
        confidence: 1.0,
      );

      expect(entry.getFormattedAmount('en'), equals('\$150.99'));
    });

    test('getFormattedDate returns localized date', () {
      final entry = HistoryEntry(
        id: '1',
        scannedAt: DateTime(2024, 3, 15),
        invoiceDate: DateTime(2024, 3, 15),
        category: InvoiceCategory.other,
        confidence: 1.0,
      );

      expect(entry.getFormattedDate('en'), equals('15 Mar 2024'));
      expect(entry.getFormattedDate('es'), equals('15 Mar 2024'));
    });

    test('handles null values gracefully in fromJson', () {
      final json = {
        'id': '123',
        'scannedAt': '2024-10-15T10:00:00.000',
        'invoiceDate': null,
        'total': null,
        'tax': null,
        'vendor': null,
        'category': null,
        'currency': null,
        'confidence': null,
      };

      final entry = HistoryEntry.fromJson(json);

      expect(entry.id, equals('123'));
      expect(entry.invoiceDate, isNull);
      expect(entry.total, isNull);
      expect(entry.vendor, isNull);
      expect(entry.category, equals(InvoiceCategory.other));
      expect(entry.confidence, equals(0.0));
    });
  });
}

