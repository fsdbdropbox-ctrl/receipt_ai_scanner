import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:receipt_ai_scanner/core/auth/auth_service.dart';
import 'package:receipt_ai_scanner/shared/models/fiscal_profile.dart';
import 'package:receipt_ai_scanner/shared/utils/constants.dart';

class FiscalProfileService {
  final AuthService _authService = AuthService();

  Future<FiscalProfile> getProfile() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/fiscal-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return FiscalProfile.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Fiscal profile not found');
      } else {
        final errorBody = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>?
            : null;
        throw Exception(
          errorBody?['message'] as String? ??
              'Failed to get fiscal profile: ${response.statusCode}',
        );
      }
    } on FormatException {
      throw Exception('Invalid response format from server');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  Future<FiscalProfile> saveProfile({
    required String countryCode,
    required String taxId,
    required String taxRegime,
    String? activitySector,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/fiscal-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'country_code': countryCode,
          'tax_id': taxId,
          'tax_regime': taxRegime,
          'activity_sector': activitySector,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return FiscalProfile.fromJson(data);
      } else {
        final errorBody = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>?
            : null;
        throw Exception(
          errorBody?['message'] as String? ??
              'Failed to save fiscal profile: ${response.statusCode}',
        );
      }
    } on FormatException {
      throw Exception('Invalid response format from server');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  Future<bool> hasProfile() async {
    try {
      await getProfile();
      return true;
    } catch (e) {
      // 404 means no profile exists (expected), other errors are real errors
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        return false;
      }
      // For other errors, log but don't throw
      return false;
    }
  }
}
