import 'package:flutter/material.dart';
import 'package:receipt_ai_scanner/core/dashboard/dashboard_service.dart';
import 'package:receipt_ai_scanner/shared/models/dashboard_metrics.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardService _dashboardService = DashboardService();
  DashboardMetrics? _metrics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final metrics = await _dashboardService.getMetrics();
      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isSpanish = locale.languageCode == 'es';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _metrics == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(_error ?? 'Error loading dashboard'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMetrics,
                child: Text(isSpanish ? 'Reintentar' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isSpanish ? 'Dashboard' : 'Dashboard',
          style: const TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            onPressed: _loadMetrics,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMetrics,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Integrity Card
              _buildIntegrityCard(context, _metrics!.integrity, isSpanish),
              const SizedBox(height: 16),
              
              // Financial Summary
              _buildFinancialCard(context, _metrics!.financial, isSpanish),
              const SizedBox(height: 16),
              
              // Issues List
              if (_metrics!.issues.isNotEmpty) ...[
                _buildIssuesSection(context, _metrics!.issues, isSpanish),
                const SizedBox(height: 16),
              ],
              
              // Validation Flags Summary
              if (_metrics!.flags.isNotEmpty) ...[
                _buildFlagsSection(context, _metrics!.flags, isSpanish),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntegrityCard(
    BuildContext context,
    IntegrityMetrics integrity,
    bool isSpanish,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSpanish ? 'Integridad Documental' : 'Document Integrity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: integrity.percentage >= 80
                        ? Colors.green[50]
                        : integrity.percentage >= 60
                            ? Colors.orange[50]
                            : Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${integrity.percentage}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: integrity.percentage >= 80
                          ? Colors.green[700]
                          : integrity.percentage >= 60
                              ? Colors.orange[700]
                              : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: integrity.percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  integrity.percentage >= 80
                      ? Colors.green
                      : integrity.percentage >= 60
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  isSpanish ? 'Válidos' : 'Valid',
                  integrity.valid.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  context,
                  isSpanish ? 'Con errores' : 'Errors',
                  integrity.invalid.toString(),
                  Colors.red,
                ),
                _buildStatItem(
                  context,
                  isSpanish ? 'Total' : 'Total',
                  integrity.total.toString(),
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard(
    BuildContext context,
    FinancialMetrics financial,
    bool isSpanish,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish ? 'Total Acumulado' : 'Total Accumulated',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${financial.totalAmount.toStringAsFixed(2)} ${financial.currency}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF2563EB),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesSection(
    BuildContext context,
    List<DocumentIssue> issues,
    bool isSpanish,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSpanish ? 'Documentos con Incidencias' : 'Documents with Issues',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            ...issues.take(5).map((issue) => _buildIssueItem(context, issue, isSpanish)),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueItem(
    BuildContext context,
    DocumentIssue issue,
    bool isSpanish,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.vendor ?? (isSpanish ? 'Sin nombre' : 'Unknown'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${issue.openFlags} ${isSpanish ? 'incidencias' : 'issues'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (issue.total != null)
            Text(
              '${issue.total!.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF2563EB),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlagsSection(
    BuildContext context,
    List<ValidationFlag> flags,
    bool isSpanish,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSpanish ? 'Tipos de Errores' : 'Error Types',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            ...flags.map((flag) => _buildFlagItem(context, flag, isSpanish)),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagItem(
    BuildContext context,
    ValidationFlag flag,
    bool isSpanish,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              flag.code,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: flag.severity == 'error' ? Colors.red[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              flag.count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: flag.severity == 'error' ? Colors.red[700] : Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
