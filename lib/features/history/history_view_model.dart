import 'package:flutter/foundation.dart';
import 'package:receipt_ai_scanner/core/history/history_service.dart';
import 'package:receipt_ai_scanner/shared/models/history_entry.dart';
import 'package:receipt_ai_scanner/shared/models/invoice_data.dart';

enum HistoryState { idle, loading, loaded, error }

class HistoryViewModel extends ChangeNotifier {
  final HistoryService _historyService;

  HistoryState _state = HistoryState.idle;
  List<HistoryEntry> _entries = [];
  Set<String> _selectedIds = {};
  bool _selectionMode = false;
  String _searchQuery = '';
  String? _errorMessage;

  HistoryViewModel({HistoryService? historyService})
      : _historyService = historyService ?? HistoryService.instance;

  // Getters
  HistoryState get state => _state;
  List<HistoryEntry> get entries => _entries;
  Set<String> get selectedIds => _selectedIds;
  bool get selectionMode => _selectionMode;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  int get selectedCount => _selectedIds.length;
  bool get hasSelection => _selectedIds.isNotEmpty;

  /// Load history entries
  Future<void> loadHistory() async {
    _state = HistoryState.loading;
    notifyListeners();

    try {
      if (_searchQuery.isEmpty) {
        _entries = await _historyService.getHistory();
      } else {
        _entries = await _historyService.searchByVendor(_searchQuery);
      }
      _state = HistoryState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = HistoryState.error;
    }
    notifyListeners();
  }

  /// Save new entry from scan result
  Future<HistoryEntry> saveEntry(InvoiceData invoiceData) async {
    final entry = await _historyService.saveEntry(invoiceData);
    await loadHistory(); // Refresh list
    return entry;
  }

  /// Toggle selection mode
  void toggleSelectionMode() {
    _selectionMode = !_selectionMode;
    if (!_selectionMode) {
      _selectedIds.clear();
    }
    notifyListeners();
  }

  /// Exit selection mode
  void exitSelectionMode() {
    _selectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  /// Toggle selection of an entry
  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    
    // Exit selection mode if no items selected
    if (_selectedIds.isEmpty && _selectionMode) {
      _selectionMode = false;
    }
    
    notifyListeners();
  }

  /// Select all entries
  void selectAll() {
    _selectedIds = _entries.map((e) => e.id).toSet();
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// Delete selected entries
  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    await _historyService.deleteEntries(_selectedIds.toList());
    _selectedIds.clear();
    _selectionMode = false;
    await loadHistory();
  }

  /// Search by vendor
  void search(String query) {
    _searchQuery = query;
    loadHistory();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    loadHistory();
  }

  /// Export selected entries to CSV
  String exportSelectedToCsv() {
    final selected = _entries.where((e) => _selectedIds.contains(e.id)).toList();
    return _historyService.exportToCsv(selected);
  }

  /// Export selected entries to JSON
  String exportSelectedToJson() {
    final selected = _entries.where((e) => _selectedIds.contains(e.id)).toList();
    return _historyService.exportToJson(selected);
  }

  /// Export all entries to CSV
  String exportAllToCsv() {
    return _historyService.exportToCsv(_entries);
  }

  /// Get monthly summary
  Future<Map<String, double>> getMonthlySummary(int year, int month) {
    return _historyService.getMonthlySummary(year, month);
  }
}

