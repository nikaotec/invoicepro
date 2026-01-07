import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/business_profile_provider.dart';
import '../invoice/new_invoice_screen.dart';
import '../dashboard/cash_flow_dashboard_screen.dart';

class OnboardingCompleteScreen extends ConsumerWidget {
  final String? businessName;
  final String? currency;
  final Future<void> Function() onComplete;

  const OnboardingCompleteScreen({
    super.key,
    this.businessName,
    this.currency,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final businessProfile = ref.watch(businessProfileProvider);
    
    final displayName = businessName ?? businessProfile.name;
    final displayCurrency = currency ?? businessProfile.currency;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Hero Illustration
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.grey[800] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF135BEC).withOpacity(0.1),
                          const Color(0xFF135BEC).withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Color(0xFF135BEC),
                    ),
                  ),
                ),
                // Decorative gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF135BEC).withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Headlines
          Text(
            'Setup Complete',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0D121B),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Your business profile is ready. It\'s time to send your first professional invoice and get paid faster.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              height: 1.5,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
            ),
          ),

          const SizedBox(height: 32),

          // Feature Highlight Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF182130) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Business Profile Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[100]!,
                            ),
                          ),
                          child: const Icon(
                            Icons.storefront,
                            color: Color(0xFF135BEC),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BUSINESS PROFILE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0D121B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Divider(
                  color: isDark ? Colors.grey[700] : Colors.grey[100],
                  height: 1,
                ),

                const SizedBox(height: 16),

                // Currency Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payments,
                          size: 18,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Currency: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey[300]
                                : Colors.grey[600],
                          ),
                        ),
                        Text(
                          displayCurrency,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF0D121B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.green[900]!.withOpacity(0.2)
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.green[400]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Create Invoice Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                // Complete onboarding first
                await onComplete();
                // Navigate to invoice creator
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const NewInvoiceScreen(),
                  ),
                );
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Create my first invoice',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Skip Link
          TextButton(
            onPressed: () async {
              await onComplete();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const CashFlowDashboardScreen(),
                ),
              );
            },
            child: Text(
              "I'll do this later",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

