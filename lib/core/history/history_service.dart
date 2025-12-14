import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipt_ai_scanner/shared/models/history_entry.dart';
import 'package:receipt_ai_scanner/shared/models/invoice_data.dart';

/// Service for managing scan history in local storage
class HistoryService {
  static const String _historyKey = 'scan_history';
  static const int _maxHistoryItems = 500; // Prevent unbounded growth

  static HistoryService? _instance;
  SharedPreferences? _prefs;
  List<HistoryEntry>? _cachedHistory;

  HistoryService._();

  static HistoryService get instance {
    _instance ??= HistoryService._();
    return _instance!;
  }

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get all history entries, sorted by scannedAt descending (newest first)
  Future<List<HistoryEntry>> getHistory() async {
    if (_cachedHistory != null) return _cachedHistory!;

    await _ensureInitialized();
    final jsonString = _prefs!.getString(_historyKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      _cachedHistory = [];
      return _cachedHistory!;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedHistory = jsonList
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      
      // Sort by scannedAt descending
      _cachedHistory!.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      
      return _cachedHistory!;
    } catch (e) {
      // If parsing fails, reset history
      _cachedHistory = [];
      return _cachedHistory!;
    }
  }

  /// Save a new entry to history (from InvoiceData)
  Future<HistoryEntry> saveEntry(InvoiceData invoiceData) async {
    final entry = HistoryEntry.fromInvoiceData(invoiceData);
    await _addEntry(entry);
    return entry;
  }

  /// Add entry to history
  Future<void> _addEntry(HistoryEntry entry) async {
    await _ensureInitialized();
    final history = await getHistory();
    
    // Add new entry at the beginning
    history.insert(0, entry);
    
    // Trim if exceeds max items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    
    await _saveHistory(history);
  }

  /// Delete entries by IDs
  Future<void> deleteEntries(List<String> ids) async {
    await _ensureInitialized();
    final history = await getHistory();
    
    history.removeWhere((entry) => ids.contains(entry.id));
    await _saveHistory(history);
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _ensureInitialized();
    _cachedHistory = [];
    await _prefs!.remove(_historyKey);
  }

  /// Search history by vendor name
  Future<List<HistoryEntry>> searchByVendor(String query) async {
    final history = await getHistory();
    if (query.isEmpty) return history;
    
    final lowerQuery = query.toLowerCase();
    return history
        .where((e) => e.vendor?.toLowerCase().contains(lowerQuery) ?? false)
        .toList();
  }

  /// Get entries by category
  Future<List<HistoryEntry>> getByCategory(InvoiceCategory category) async {
    final history = await getHistory();
    return history.where((e) => e.category == category).toList();
  }

  /// Get entries by date range
  Future<List<HistoryEntry>> getByDateRange(DateTime start, DateTime end) async {
    final history = await getHistory();
    return history.where((e) {
      final date = e.invoiceDate ?? e.scannedAt;
      return date.isAfter(start) && date.isBefore(end);
    }).toList();
  }

  /// Export entries to CSV string
  String exportToCsv(List<HistoryEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Vendor,Total,Tax,Currency,Category');
    
    for (final entry in entries) {
      buffer.writeln(entry.toCsvRow());
    }
    
    return buffer.toString();
  }

  /// Export entries to TSV string (for Excel/Sheets paste)
  /// Always includes header for context
  String exportToTsv(List<HistoryEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln(HistoryEntry.tsvHeader);
    
    for (final entry in entries) {
      buffer.writeln(entry.toTsvRow());
    }
    
    return buffer.toString().trimRight(); // Remove trailing newline
  }

  /// Export entries to JSON string
  String exportToJson(List<HistoryEntry> entries) {
    final jsonList = entries.map((e) => e.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }

  /// Get monthly summary
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final history = await getHistory();
    
    final monthEntries = history.where((e) {
      final date = e.invoiceDate ?? e.scannedAt;
      return date.year == year && date.month == month;
    });

    final summary = <String, double>{};
    double totalAmount = 0;
    double totalTax = 0;

    for (final entry in monthEntries) {
      final categoryName = entry.category.name;
      summary[categoryName] = (summary[categoryName] ?? 0) + (entry.total ?? 0);
      totalAmount += entry.total ?? 0;
      totalTax += entry.tax ?? 0;
    }

    summary['_total'] = totalAmount;
    summary['_tax'] = totalTax;
    summary['_count'] = monthEntries.length.toDouble();

    return summary;
  }

  /// Save history to storage
  Future<void> _saveHistory(List<HistoryEntry> history) async {
    _cachedHistory = history;
    final jsonList = history.map((e) => e.toJson()).toList();
    await _prefs!.setString(_historyKey, json.encode(jsonList));
  }
}

