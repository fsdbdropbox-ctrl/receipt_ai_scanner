import 'package:flutter/material.dart';
import 'package:receipt_ai_scanner/core/auth/auth_service.dart';
import 'package:receipt_ai_scanner/core/fiscal/fiscal_profile_service.dart';
import 'package:receipt_ai_scanner/features/auth/auth_view.dart';
import 'package:receipt_ai_scanner/features/onboarding/onboarding_view.dart';
import 'package:receipt_ai_scanner/features/home/home_shell.dart';

class AppRouter {
  static Future<Widget> getInitialRoute() async {
    try {
      final authService = AuthService();
      final fiscalService = FiscalProfileService();

      // Check if user is authenticated
      final isAuthenticated = await authService.isAuthenticated();
      if (!isAuthenticated) {
        return const AuthView();
      }

      // Check if user has fiscal profile
      final hasProfile = await fiscalService.hasProfile();
      if (!hasProfile) {
        return const OnboardingView();
      }

      // User is authenticated and has profile - go to home
      return const HomeShell();
    } catch (e) {
      // If anything fails, show auth screen
      return const AuthView();
    }
  }
}
