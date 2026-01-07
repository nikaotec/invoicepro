import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Billing period provider
final billingPeriodProvider = StateProvider<BillingPeriod>((ref) => BillingPeriod.yearly);

enum BillingPeriod { monthly, yearly }

class PricingPlanScreen extends ConsumerStatefulWidget {
  const PricingPlanScreen({super.key});

  @override
  ConsumerState<PricingPlanScreen> createState() => _PricingPlanScreenState();
}

class _PricingPlanScreenState extends ConsumerState<PricingPlanScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final billingPeriod = ref.watch(billingPeriodProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Headline
                    _buildHeadline(context, isDark),

                    const SizedBox(height: 24),

                    // Segmented Control
                    _buildSegmentedControl(context, isDark, billingPeriod),

                    const SizedBox(height: 24),

                    // Pricing Cards
                    _buildPricingCards(context, isDark, billingPeriod),

                    const SizedBox(height: 16),

                    // Trust Signal
                    _buildTrustSignal(context, isDark),

                    const SizedBox(height: 100), // Space for bottom CTA
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Sticky Bottom CTA
      bottomNavigationBar: _buildBottomCTA(context, isDark),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          Text(
            'Pricing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 48), // Spacer for balance
        ],
      ),
    );
  }

  Widget _buildHeadline(BuildContext context, bool isDark) {
    return Column(
      children: [
        Text(
          'Unlock full potential',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Upgrade to manage unlimited clients and automate your workflow.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSegmentedControl(
    BuildContext context,
    bool isDark,
    BillingPeriod currentPeriod,
  ) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegment(
              context,
              isDark,
              label: 'Monthly',
              isSelected: currentPeriod == BillingPeriod.monthly,
              onTap: () {
                ref.read(billingPeriodProvider.notifier).state =
                    BillingPeriod.monthly;
              },
            ),
          ),
          Expanded(
            child: _buildSegment(
              context,
              isDark,
              label: 'Yearly',
              badge: '-20%',
              isSelected: currentPeriod == BillingPeriod.yearly,
              onTap: () {
                ref.read(billingPeriodProvider.notifier).state =
                    BillingPeriod.yearly;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context,
    bool isDark, {
    required String label,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.grey[700] : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.green[100]
                      : (isDark ? Colors.green[900]!.withOpacity(0.3) : Colors.green[50]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.green[700]
                        : (isDark ? Colors.green[400] : Colors.green[600]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCards(
    BuildContext context,
    bool isDark,
    BillingPeriod billingPeriod,
  ) {
    return Column(
      children: [
        // Starter Plan
        _buildPlanCard(
          context,
          isDark,
          title: 'Starter',
          subtitle: 'Perfect for getting started',
          price: '\$0',
          period: '/mo',
          features: const [
            'Up to 3 active clients',
            'Basic invoicing & PDF export',
            'Standard support',
          ],
          isHighlighted: false,
        ),

        const SizedBox(height: 20),

        // Pro Plan (Highlighted)
        _buildPlanCard(
          context,
          isDark,
          title: 'Pro',
          subtitle: 'For growing businesses',
          price: billingPeriod == BillingPeriod.yearly ? '\$12' : '\$15',
          originalPrice: billingPeriod == BillingPeriod.yearly ? '\$15' : null,
          period: billingPeriod == BillingPeriod.yearly
              ? '/mo, billed yearly'
              : '/mo',
          features: const [
            'Unlimited clients',
            'Automated payment reminders',
            'Custom branding & logos',
            'Multi-currency support',
            'Priority 24/7 support',
          ],
          isHighlighted: true,
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String subtitle,
    required String price,
    String? originalPrice,
    required String period,
    required List<String> features,
    required bool isHighlighted,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF135BEC)
              : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFF135BEC).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
          if (isHighlighted)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF135BEC),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Title and Price Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isHighlighted
                              ? const Color(0xFF135BEC)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (originalPrice != null)
                        Text(
                          originalPrice,
                          style: TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            price,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            period,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Divider
              Divider(
                color: isDark ? Colors.grey[700] : Colors.grey[200],
                height: 1,
              ),

              const SizedBox(height: 16),

              // Features List
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          isHighlighted ? Icons.check_circle : Icons.check,
                          size: 20,
                          color: isHighlighted
                              ? const Color(0xFF135BEC)
                              : (isDark ? Colors.grey[400] : Colors.grey[400]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isHighlighted
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: isHighlighted
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : (isDark ? Colors.grey[300] : Colors.grey[700]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustSignal(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        'Secure payments via Stripe. Cancel anytime from your account settings.',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF101622) : Colors.white).withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  // Show subscription confirmation
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                      title: Text(
                        'Start Free Trial',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      content: Text(
                        'You\'ll start a 14-day free trial of the Pro plan. No credit card required.',
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF135BEC),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Trial'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    // TODO: Integrate with actual subscription service (Stripe, RevenueCat, etc.)
                    // For now, just show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Free trial started successfully!'),
                        backgroundColor: Colors.green,
                        action: SnackBarAction(
                          label: 'OK',
                          textColor: Colors.white,
                          onPressed: () {},
                        ),
                      ),
                    );
                    // Optionally navigate back
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF135BEC).withOpacity(0.25),
                ),
                child: const Text(
                  'Start 14-day free trial',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No credit card required for trial',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
