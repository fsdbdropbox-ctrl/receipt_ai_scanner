import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:receipt_ai_scanner/core/auth/installation_id_service.dart';
import 'package:receipt_ai_scanner/shared/utils/constants.dart';
import 'package:receipt_ai_scanner/shared/widgets/quota_banner.dart';

/// Service for fetching quota information from the backend
class QuotaService {
  final InstallationIdService _installationIdService;

  QuotaService({InstallationIdService? installationIdService})
      : _installationIdService = installationIdService ?? InstallationIdService();

  /// Fetch current quota from the backend
  Future<QuotaInfo> fetchQuota() async {
    try {
      final installId = await _installationIdService.getInstallationId();
      
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/quota'),
        headers: {
          'X-Install-Id': installId,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final quotaJson = json['quota'] as Map<String, dynamic>;
        return QuotaInfo.fromJson(quotaJson);
      } else {
        // Return default quota on error
        return QuotaInfo.simple(scansLeft: 5, isPremium: false);
      }
    } catch (e) {
      // Return default quota on network error
      return QuotaInfo.simple(scansLeft: 5, isPremium: false);
    }
  }
}

