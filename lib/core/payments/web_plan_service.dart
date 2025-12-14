import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:receipt_ai_scanner/shared/utils/constants.dart';
import 'package:receipt_ai_scanner/core/auth/installation_id_service.dart';
import 'package:receipt_ai_scanner/core/utils/json_parser.dart';

class WebPlanService {
  final InstallationIdService _installationIdService;
  final String _apiBaseUrl;
  bool? _cachedPremiumStatus;

  WebPlanService({
    InstallationIdService? installationIdService,
    String? apiBaseUrl,
  })  : _installationIdService = installationIdService ?? InstallationIdService(),
        _apiBaseUrl = apiBaseUrl ?? AppConstants.apiBaseUrl;

  Future<void> initialize() async {
    await refreshPremiumStatus();
  }

  Future<bool> isPremium() async {
    if (_cachedPremiumStatus != null) return _cachedPremiumStatus!;
    return await refreshPremiumStatus();
  }

  Future<bool> refreshPremiumStatus() async {
    try {
      final installId = await _installationIdService.getInstallationId();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/me'),
        headers: {'X-Install-Id': installId},
      );

      if (response.statusCode == 200) {
        final json = response.body.isNotEmpty
            ? (RobustJsonParser.tryParse(response.body) as Map<String, dynamic>?)
            : null;
        _cachedPremiumStatus = json?['isPremium'] as bool? ?? false;
        return _cachedPremiumStatus!;
      }
    } catch (_) {}
    _cachedPremiumStatus = false;
    return false;
  }

  Future<String?> createCheckoutSession() async {
    try {
      final installId = await _installationIdService.getInstallationId();
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/create-checkout-session'),
        headers: {
          'X-Install-Id': installId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'installId': installId}),
      );

      if (response.statusCode == 200) {
        final json = RobustJsonParser.tryParse(response.body) as Map<String, dynamic>;
        return json['url'] as String?;
      }
    } catch (_) {}
    return null;
  }
}

