import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TaxRateOnboardingScreen extends StatefulWidget {
  final double? initialValue;
  final ValueChanged<double> onChanged;
  final VoidCallback onComplete;

  const TaxRateOnboardingScreen({
    super.key,
    this.initialValue,
    required this.onChanged,
    required this.onComplete,
  });

  @override
  State<TaxRateOnboardingScreen> createState() =>
      _TaxRateOnboardingScreenState();
}

class _TaxRateOnboardingScreenState extends State<TaxRateOnboardingScreen> {
  final _controller = TextEditingController();
  double _taxRate = 0.0;

  @override
  void initState() {
    super.initState();
    _taxRate = widget.initialValue ?? 0.0;
    _controller.text = _taxRate.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateTaxRate(String value) {
    final parsed = double.tryParse(value) ?? 0.0;
    setState(() {
      _taxRate = parsed.clamp(0.0, 100.0);
      widget.onChanged(_taxRate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Headline
          Text(
            'Set your default tax rate',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // Body Text
          Text(
            'This will be applied to all new invoices by default. You can adjust it for each invoice individually.',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 32),

          // Tax Rate Input
          Stack(
            children: [
              TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? Colors.grey[800]!.withOpacity(0.5)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF135BEC),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 24),
                ),
                onChanged: _updateTaxRate,
              ),
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    '%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Select Buttons
          Text(
            'Quick select',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [0.0, 5.0, 10.0, 15.0, 20.0].map((rate) {
              final isSelected = _taxRate == rate;
              return InkWell(
                onTap: () {
                  setState(() {
                    _taxRate = rate;
                    _controller.text = rate.toStringAsFixed(1);
                  });
                  widget.onChanged(_taxRate);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF135BEC)
                        : (isDark
                            ? Colors.grey[800]!.withOpacity(0.5)
                            : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF135BEC)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '${rate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey[300] : Colors.black87),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 48),

          // Complete Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onChanged(_taxRate);
                widget.onComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF135BEC).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Complete Setup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

