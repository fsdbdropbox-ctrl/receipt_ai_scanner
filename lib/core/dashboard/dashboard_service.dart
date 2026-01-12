import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:receipt_ai_scanner/core/auth/auth_service.dart';
import 'package:receipt_ai_scanner/shared/models/dashboard_metrics.dart';
import 'package:receipt_ai_scanner/shared/utils/constants.dart';

class DashboardService {
  final AuthService _authService = AuthService();

  Future<DashboardMetrics> getMetrics() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/dashboard/metrics'),
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
        return DashboardMetrics.fromJson(data);
      } else {
        final errorBody = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>?
            : null;
        throw Exception(
          errorBody?['message'] as String? ??
              'Failed to get dashboard metrics: ${response.statusCode}',
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
}
