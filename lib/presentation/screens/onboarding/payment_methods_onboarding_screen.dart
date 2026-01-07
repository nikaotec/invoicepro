import 'package:flutter/material.dart';

class PaymentMethod {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? recommendation;
  bool isEnabled;
  bool isDefault;

  PaymentMethod({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.recommendation,
    this.isEnabled = false,
    this.isDefault = false,
  });
}

class PaymentMethodsOnboardingScreen extends StatefulWidget {
  final Map<String, bool>? initialEnabled;
  final String? initialDefault;
  final ValueChanged<Map<String, bool>> onEnabledChanged;
  final ValueChanged<String?> onDefaultChanged;
  final VoidCallback onNext;

  const PaymentMethodsOnboardingScreen({
    super.key,
    this.initialEnabled,
    this.initialDefault,
    required this.onEnabledChanged,
    required this.onDefaultChanged,
    required this.onNext,
  });

  @override
  State<PaymentMethodsOnboardingScreen> createState() =>
      _PaymentMethodsOnboardingScreenState();
}

class _PaymentMethodsOnboardingScreenState
    extends State<PaymentMethodsOnboardingScreen> {
  late List<PaymentMethod> _paymentMethods;
  String? _defaultMethod;

  @override
  void initState() {
    super.initState();
    
    // Initialize payment methods
    _paymentMethods = [
      PaymentMethod(
        id: 'bank_transfer',
        title: 'Bank Transfer',
        subtitle: 'SEPA / ACH / Wire',
        icon: Icons.account_balance,
        recommendation: 'Recommended for B2B & International',
        isEnabled: widget.initialEnabled?['bank_transfer'] ?? true,
        isDefault: widget.initialDefault == 'bank_transfer',
      ),
      PaymentMethod(
        id: 'credit_debit',
        title: 'Credit & Debit Cards',
        subtitle: 'Visa, Mastercard, Amex',
        icon: Icons.credit_card,
        isEnabled: widget.initialEnabled?['credit_debit'] ?? true,
        isDefault: widget.initialDefault == 'credit_debit',
      ),
      PaymentMethod(
        id: 'digital_wallets',
        title: 'Digital Wallets',
        subtitle: 'Apple Pay, Google Pay',
        icon: Icons.wallet,
        isEnabled: widget.initialEnabled?['digital_wallets'] ?? false,
        isDefault: widget.initialDefault == 'digital_wallets',
      ),
      PaymentMethod(
        id: 'crypto',
        title: 'Crypto Settlement',
        subtitle: 'USDC Stablecoin',
        icon: Icons.currency_bitcoin,
        isEnabled: widget.initialEnabled?['crypto'] ?? false,
        isDefault: widget.initialDefault == 'crypto',
      ),
    ];

    // Set default method
    _defaultMethod = widget.initialDefault ?? 'bank_transfer';
    _paymentMethods.firstWhere((m) => m.id == 'bank_transfer').isDefault = true;
  }

  void _toggleMethod(String methodId) {
    setState(() {
      final method = _paymentMethods.firstWhere((m) => m.id == methodId);
      
      // Prevent disabling if it's the only enabled method
      final enabledCount = _paymentMethods.where((m) => m.isEnabled).length;
      if (method.isEnabled && enabledCount <= 1) {
        // Can't disable the last enabled method
        return;
      }

      method.isEnabled = !method.isEnabled;

      // If disabling the default method, set first enabled as default
      if (method.isDefault && !method.isEnabled) {
        final firstEnabled = _paymentMethods.firstWhere(
          (m) => m.isEnabled && m.id != methodId,
        );
        _paymentMethods.forEach((m) => m.isDefault = false);
        firstEnabled.isDefault = true;
        _defaultMethod = firstEnabled.id;
      }

      // If enabling a method and no default exists, set it as default
      if (method.isEnabled && _defaultMethod == null) {
        _paymentMethods.forEach((m) => m.isDefault = false);
        method.isDefault = true;
        _defaultMethod = method.id;
      }

      // Update enabled methods
      final enabledMap = {
        for (var m in _paymentMethods) m.id: m.isEnabled
      };
      widget.onEnabledChanged(enabledMap);
      widget.onDefaultChanged(_defaultMethod);
    });
  }

  void _setDefault(String methodId) {
    setState(() {
      _paymentMethods.forEach((m) => m.isDefault = false);
      final method = _paymentMethods.firstWhere((m) => m.id == methodId);
      method.isDefault = true;
      method.isEnabled = true; // Default must be enabled
      _defaultMethod = methodId;

      final enabledMap = {
        for (var m in _paymentMethods) m.id: m.isEnabled
      };
      widget.onEnabledChanged(enabledMap);
      widget.onDefaultChanged(_defaultMethod);
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
            'How do you want to get paid?',
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
            'You can enable more than one option. Choose a default for your invoices.',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 32),

          // Payment Methods List
          ..._paymentMethods.map((method) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPaymentMethodCard(context, method, isDark),
            );
          }),

          const SizedBox(height: 32),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onNext,
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
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Skip link
          Center(
            child: TextButton(
              onPressed: widget.onNext,
              child: Text(
                "I'll configure this later",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context,
    PaymentMethod method,
    bool isDark,
  ) {
    final isSelected = method.isDefault;
    final primaryColor = const Color(0xFF135BEC);

    return InkWell(
      onTap: () => _setDefault(method.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : (isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                if (isSelected) const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withOpacity(0.2)
                              : (isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          method.icon,
                          color: isSelected
                              ? primaryColor
                              : (isDark ? Colors.grey[300] : Colors.black87),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              method.subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            if (method.recommendation != null &&
                                method.isEnabled)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      method.recommendation!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Switch(
                        value: method.isEnabled,
                        onChanged: (value) => _toggleMethod(method.id),
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

