import 'package:flutter/material.dart';
import 'package:receipt_ai_scanner/core/payments/web_plan_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallView extends StatelessWidget {
  const PaywallView({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isSpanish = locale.startsWith('es');

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Actualizar' : 'Upgrade'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.star,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              isSpanish ? 'Escaneos ilimitados' : 'Unlimited scans',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isSpanish ? '7 días gratis de prueba' : '7 days free trial',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSpanish
                  ? 'Escanea todas las facturas que necesites sin límites diarios'
                  : 'Scan all the invoices you need without daily limits',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildFeatureList(context, isSpanish),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleUpgrade(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isSpanish ? 'Desbloquear escaneos ilimitados' : 'Unlock Unlimited Scans',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSpanish ? 'Después del período de prueba: \$9.99/mes. Cancelar en cualquier momento.' : 'After trial: \$9.99/mo. Cancel anytime.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context, bool isSpanish) {
    return Column(
      children: [
        _buildFeatureItem(
          context,
          Icons.check_circle,
          isSpanish ? 'Escaneos ilimitados' : 'Unlimited scans',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          context,
          Icons.check_circle,
          isSpanish ? 'Sin límites diarios' : 'No daily limits',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          context,
          Icons.check_circle,
          isSpanish ? 'Extracción precisa de datos' : 'Accurate data extraction',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpgrade(BuildContext context) async {
    final webPlanService = WebPlanService();
    final checkoutUrl = await webPlanService.createCheckoutSession();
    
    if (checkoutUrl != null && await canLaunchUrl(Uri.parse(checkoutUrl))) {
      await launchUrl(Uri.parse(checkoutUrl));
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening checkout')),
        );
      }
    }
  }
}

