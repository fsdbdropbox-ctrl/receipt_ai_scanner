import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:receipt_ai_scanner/core/auth/auth_service.dart';
import 'package:receipt_ai_scanner/shared/utils/constants.dart';

class ReviewView extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> extractedData;
  final List<dynamic> validationErrors;
  final String? userTaxId;

  const ReviewView({
    super.key,
    required this.documentId,
    required this.extractedData,
    required this.validationErrors,
    this.userTaxId,
  });

  @override
  State<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  final AuthService _authService = AuthService();
  bool _isFixing = false;
  List<dynamic> _currentErrors = [];

  @override
  void initState() {
    super.initState();
    _currentErrors = List.from(widget.validationErrors);
  }

  Future<void> _autoFixNIF(String flagCode) async {
    setState(() => _isFixing = true);

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v2/documents/${widget.documentId}/fix'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'flagCode': flagCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentErrors = (data['data']['validation_errors'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ NIF autocorregido'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to fix');
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
        setState(() => _isFixing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isSpanish = locale.languageCode == 'es';

    // Find missing NIF error
    final missingNifError = _currentErrors.firstWhere(
      (error) => error.toString().contains('21') || error.toString().contains('NIF'),
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Revisar Documento' : 'Review Document'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Document Data Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.extractedData['vendor'] ?? 'Sin vendedor',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.extractedData['total'] != null)
                      Text(
                        '${widget.extractedData['total']} ${widget.extractedData['currency'] ?? 'EUR'}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Validation Issues
            if (missingNifError != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.scale, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          isSpanish ? 'Incidencia Formal (ES-21)' : 'Formal Issue (ES-21)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        isSpanish
                            ? 'Falta tu NIF en la factura recibida. Hacienda no permite deducir esto sin rectificación.'
                            : 'Your Tax ID is missing from the received invoice. Tax authority does not allow deduction without rectification.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isFixing
                              ? null
                              : () => _autoFixNIF(missingNifError.toString()),
                          icon: _isFixing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_fix_high, size: 16),
                          label: Text(
                            isSpanish
                                ? 'Autocompletar mi NIF (${widget.userTaxId?.substring(0, 3)}...)'
                                : 'Auto-fill my Tax ID (${widget.userTaxId?.substring(0, 3)}...)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Other validation errors
            if (_currentErrors.isNotEmpty && missingNifError == null) ...[
              ..._currentErrors.map((error) => Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              error.toString(),
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],

            // Success state
            if (_currentErrors.isEmpty) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Text(
                        isSpanish ? 'Documento válido' : 'Document valid',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
