import 'package:receipt_ai_scanner/core/payments/entitlement_service.dart';
import 'package:receipt_ai_scanner/core/payments/web_plan_service.dart';

class WebEntitlementService implements EntitlementService {
  final WebPlanService _webPlanService = WebPlanService();

  @override
  Future<bool> isPremium() async {
    return await _webPlanService.isPremium();
  }

  @override
  Future<void> initialize() async {
    await _webPlanService.initialize();
  }
}

