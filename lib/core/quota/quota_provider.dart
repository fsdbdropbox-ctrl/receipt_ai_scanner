import 'package:flutter/foundation.dart';
import 'package:receipt_ai_scanner/core/quota/quota_service.dart';
import 'package:receipt_ai_scanner/shared/widgets/quota_banner.dart';

/// Provider for managing quota state globally
class QuotaProvider extends ChangeNotifier {
  final QuotaService _quotaService;

  QuotaInfo _quotaInfo = const QuotaInfo(scansLeft: 5, isPremium: false);
  bool _isLoading = false;
  String? _error;

  QuotaProvider({QuotaService? quotaService})
      : _quotaService = quotaService ?? QuotaService();

  QuotaInfo get quotaInfo => _quotaInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get scansLeft => _quotaInfo.scansLeft;
  bool get isPremium => _quotaInfo.isPremium;
  bool get limitReached => _quotaInfo.limitReached;

  /// Fetch quota from backend
  Future<void> refreshQuota() async {
    if (_isLoading) return; // Prevent concurrent fetches

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _quotaInfo = await _quotaService.fetchQuota();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update quota after a successful scan (called from ScanViewModel)
  void updateQuota(QuotaInfo newQuotaInfo) {
    _quotaInfo = newQuotaInfo;
    notifyListeners();
  }

  /// Decrement quota locally (optimistic update)
  void decrementQuota() {
    if (_quotaInfo.scansLeft > 0) {
      _quotaInfo = QuotaInfo(
        scansLeft: _quotaInfo.scansLeft - 1,
        scansUsed: (_quotaInfo.scansUsed ?? 0) + 1,
        limit: _quotaInfo.limit,
        period: _quotaInfo.period,
        daysUntilReset: _quotaInfo.daysUntilReset,
        isPremium: _quotaInfo.isPremium,
        limitReached: _quotaInfo.scansLeft - 1 <= 0,
      );
      notifyListeners();
    }
  }
}

