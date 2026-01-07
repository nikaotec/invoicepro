import 'package:flutter/material.dart';

class CurrencyOnboardingScreen extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const CurrencyOnboardingScreen({
    super.key,
    this.initialValue,
    required this.onChanged,
    required this.onNext,
  });

  @override
  State<CurrencyOnboardingScreen> createState() =>
      _CurrencyOnboardingScreenState();
}

class _CurrencyOnboardingScreenState extends State<CurrencyOnboardingScreen> {
  String? _selectedCurrency;

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'BRL', 'symbol': 'R\$', 'name': 'Brazilian Real'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.initialValue ?? 'USD';
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
            'Choose your currency',
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
            'Select the primary currency for your invoices. You can change this later in settings.',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 32),

          // Currency List
          ..._currencies.map((currency) {
            final isSelected = _selectedCurrency == currency['code'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCurrency = currency['code'];
                  });
                  widget.onChanged(currency['code']!);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF135BEC).withOpacity(0.1)
                        : (isDark
                            ? Colors.grey[800]!.withOpacity(0.5)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF135BEC)
                          : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF135BEC)
                              : (isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            currency['symbol']!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.grey[300]
                                      : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currency['name']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currency['code']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF135BEC),
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 32),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedCurrency != null
                  ? () {
                      widget.onChanged(_selectedCurrency!);
                      widget.onNext();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF135BEC).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor:
                    const Color(0xFF135BEC).withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

