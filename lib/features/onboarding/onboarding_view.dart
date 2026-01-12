import 'package:flutter/material.dart';
import 'package:receipt_ai_scanner/core/fiscal/fiscal_profile_service.dart';
import 'package:receipt_ai_scanner/shared/models/fiscal_profile.dart';
import 'package:receipt_ai_scanner/features/home/home_shell.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _formKey = GlobalKey<FormState>();
  final _taxIdController = TextEditingController();
  final FiscalProfileService _fiscalService = FiscalProfileService();
  
  SupportedCountry _selectedCountry = SupportedCountry.es;
  TaxRegime _selectedRegime = TaxRegime.autonomo;
  bool _isLoading = false;

  @override
  void dispose() {
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _fiscalService.saveProfile(
        countryCode: _selectedCountry.code,
        taxId: _taxIdController.text.trim().toUpperCase(),
        taxRegime: _selectedRegime.name,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isSpanish = locale.languageCode == 'es';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  isSpanish ? 'Configura tu Bóveda' : 'Configure your Vault',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  isSpanish
                      ? 'Para validar tus documentos, necesitamos tu contexto fiscal.'
                      : 'To validate your documents, we need your fiscal context.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),
                
                // Country Selection
                Text(
                  isSpanish ? 'País Fiscal' : 'Fiscal Country',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<SupportedCountry>(
                    value: _selectedCountry,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: SupportedCountry.values.map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text('${country.flag} ${country.name}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCountry = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Tax ID Input
                Text(
                  isSpanish ? 'Tu NIF / RFC / VAT ID' : 'Your Tax ID / VAT ID',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _taxIdController,
                  decoration: InputDecoration(
                    hintText: isSpanish ? 'Ej. B12345678' : 'E.g. B12345678',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isSpanish ? 'Campo obligatorio' : 'Required field';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  isSpanish
                      ? 'Usaremos esto para validar que las facturas van a tu nombre.'
                      : 'We will use this to validate that invoices are in your name.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                ),
                const SizedBox(height: 24),
                
                // Tax Regime Selection
                Text(
                  isSpanish ? 'Régimen' : 'Tax Regime',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildRegimeButton(
                        context,
                        TaxRegime.autonomo,
                        isSpanish,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRegimeButton(
                        context,
                        TaxRegime.empresa,
                        isSpanish,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isSpanish ? 'Guardar y Entrar' : 'Save and Continue',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegimeButton(
    BuildContext context,
    TaxRegime regime,
    bool isSpanish,
  ) {
    final isSelected = _selectedRegime == regime;
    
    return InkWell(
      onTap: () => setState(() => _selectedRegime = regime),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEFF6FF)
              : Colors.grey[50],
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            regime.getDisplayName(isSpanish ? 'es' : 'en'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
