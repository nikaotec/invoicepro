import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/business_profile_provider.dart';

class CurrencyTaxSettingsScreen extends ConsumerStatefulWidget {
  const CurrencyTaxSettingsScreen({super.key});

  @override
  ConsumerState<CurrencyTaxSettingsScreen> createState() =>
      _CurrencyTaxSettingsScreenState();
}

class _CurrencyTaxSettingsScreenState
    extends ConsumerState<CurrencyTaxSettingsScreen> {
  final _taxRateController = TextEditingController();
  String? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(businessProfileProvider);
    _selectedCurrency = profile.currency;
    _taxRateController.text = (profile.taxRate * 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    super.dispose();
  }

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'BRL',
    'CAD',
    'AUD',
    'JPY',
    'CNY',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ref.watch(businessProfileProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Currency & Tax Rates',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Currency Section
              Text(
                'Currency',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedCurrency ?? profile.currency,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _currencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(
                        currency,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Tax Rate Section
              Text(
                'Default Tax Rate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: TextField(
                  controller: _taxRateController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Tax Rate (%)',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    suffixText: '%',
                    suffixStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
                    ref.read(businessProfileProvider.notifier).updateProfile(
                      currency: _selectedCurrency ?? profile.currency,
                      taxRate: taxRate / 100,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

