import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../widgets/dashboard/modern_balance_card.dart';
import '../../widgets/dashboard/quick_action_button.dart';
import '../../widgets/dashboard/activity_item.dart';
import '../../providers/invoice_provider.dart';
import '../../../data/models/invoice_model.dart';

/// Modern Dashboard screen with command center design
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final invoiceState = ref.watch(invoiceProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Balance card (Driven by Provider)
                      statsAsync.when(
                        data: (stats) => ModernBalanceCard(
                          balance: NumberFormat.simpleCurrency().format(
                            stats['totalRevenue'],
                          ),
                          changePercentage:
                              '+12%', // Mocked for now or calculate if needed
                          isPositiveChange: true,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox(),
                      ),

                      const SizedBox(height: 32),

                      // Quick actions
                      _buildQuickActions(context),

                      const SizedBox(height: 32),

                      // Recent activity (Driven by Provider)
                      _buildRecentActivity(context, invoiceState.invoices),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // User avatar with online indicator
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                      image: const DecorationImage(
                        image: AssetImage(
                          'assets/images/avatars/user_avatar.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Alex Morgan',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildIconButton(context, Icons.search, onTap: () {}),
              const SizedBox(width: 12),
              _buildIconButton(
                context,
                Icons.notifications_outlined,
                hasNotification: true,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon, {
    bool hasNotification = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Material(
          color: theme.cardColor,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(icon, size: 22, color: theme.colorScheme.onSurface),
            ),
          ),
        ),
        if (hasNotification)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: theme.cardColor, width: 1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        QuickActionButton(
          icon: Icons.person_add_outlined,
          label: 'Add Client',
          backgroundColor: isDark
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.indigoBackground,
          iconColor: isDark ? AppColors.primary : AppColors.primary,
          onTap: () {},
        ),
        QuickActionButton(
          icon: Icons.document_scanner_outlined,
          label: 'Scan',
          backgroundColor: isDark
              ? AppColors.purpleIcon.withOpacity(0.15)
              : AppColors.purpleBackground,
          iconColor: isDark ? AppColors.purpleIcon : AppColors.purpleIcon,
          onTap: () {},
        ),
        QuickActionButton(
          icon: Icons.analytics_outlined,
          label: 'Reports',
          backgroundColor: isDark
              ? AppColors.blueIcon.withOpacity(0.15)
              : AppColors.blueBackground,
          iconColor: isDark ? AppColors.blueIcon : AppColors.blueIcon,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<Invoice> invoices) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View all',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppDimensions.radius3xl),
            border: Border.all(
              color: theme.dividerColor.withOpacity(isDark ? 0.2 : 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: const Offset(0, 10),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (invoices.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                ...invoices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final invoice = entry.value;
                  final isLast = index == invoices.length - 1;

                  return Column(
                    children: [
                      ActivityItem(
                        // Mock logic for avatars/initials
                        initials: invoice.clientName
                            .substring(0, 2)
                            .toUpperCase(),
                        initialsBackgroundColor:
                            theme.colorScheme.primaryContainer,
                        initialsTextColor: theme.colorScheme.onPrimaryContainer,
                        title: invoice.clientName,
                        subtitle:
                            '${invoice.number} • ${DateFormat('MMM d').format(invoice.date)}',
                        amount: NumberFormat.simpleCurrency().format(
                          invoice.amount,
                        ),
                        status: invoice.status.label, // Or use enum name
                        isPaid: invoice.status == InvoiceStatus.paid,
                        onTap: () {},
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color:
                              theme.dividerTheme.color?.withOpacity(0.2) ??
                              AppColors.borderLight,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
