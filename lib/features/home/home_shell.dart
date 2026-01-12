import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_ai_scanner/features/scan/scan_view.dart';
import 'package:receipt_ai_scanner/features/history/history_view.dart';
import 'package:receipt_ai_scanner/features/history/history_view_model.dart';
import 'package:receipt_ai_scanner/features/dashboard/dashboard_view.dart';
import 'package:receipt_ai_scanner/shared/widgets/bottom_navigation.dart';

/// Main shell that contains the bottom navigation and switches between views
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppTab _currentTab = AppTab.dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: AppBottomNavigation(
        currentTab: _currentTab,
        onTabChanged: (tab) {
          setState(() => _currentTab = tab);
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case AppTab.dashboard:
        return const DashboardView();
      case AppTab.scan:
        return const ScanView();
      case AppTab.history:
        return ChangeNotifierProvider(
          create: (_) => HistoryViewModel(),
          child: const HistoryView(),
        );
    }
  }
}

