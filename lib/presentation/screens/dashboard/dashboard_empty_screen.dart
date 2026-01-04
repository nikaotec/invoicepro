import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/dashboard/empty_state_card.dart';
import '../invoice/smart_invoice_creator_screen.dart';

/// Dashboard screen with empty state when no invoices exist
class DashboardEmptyScreen extends ConsumerWidget {
  const DashboardEmptyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Remove floating action button from here as it's handled in main.dart (or hidden)

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // Fixed bottom navigation simulation for "Command Center" look if needed,
      // but main.dart handles actual navigation.
      // We focus on the body content matching the HTML.
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Top Row (Avatar & Actions)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // User Avatar
                          Container(
                            width: 40,
                            height: 40,
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
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          // Actions
                          Row(
                            children: [
                              _buildHeaderIconButton(context, Icons.search),
                              const SizedBox(width: 8),
                              _buildHeaderIconButton(
                                context,
                                Icons.notifications_outlined,
                                hasDot: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Titles
                      Text(
                        'VISÃO GERAL',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bom dia, Alex',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Welcome Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: EmptyStateCard(
                    onCreateInvoice: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SmartInvoiceCreatorScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.person_add_outlined,
                          label: 'Novo Cliente',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.document_scanner_outlined,
                          label: 'Escanear',
                          color: Colors.purple,
                          isPurple: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.analytics_outlined,
                          label: 'Relatórios',
                          color: Colors.blue,
                          isBlue: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fixed Bottom Gradient Blur (Optional, to match HTML's bottom bar feel if desired,
          // though main.dart has the nav bar. We'll skip adding a fake nav bar to avoid duplication.)
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(
    BuildContext context,
    IconData icon, {
    bool hasDot = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurface),
          if (hasDot)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardColor, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    bool isPurple = false,
    bool isBlue = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgIconColor;
    Color iconColor;

    if (isPurple) {
      bgIconColor = isDark
          ? Colors.purple.withOpacity(0.2)
          : Colors.purple.shade100;
      iconColor = isDark ? Colors.purple.shade300 : Colors.purple.shade600;
    } else if (isBlue) {
      bgIconColor = isDark
          ? Colors.blue.withOpacity(0.2)
          : Colors.blue.shade100;
      iconColor = isDark ? Colors.blue.shade300 : Colors.blue.shade600;
    } else {
      // Default Primary
      bgIconColor = theme.colorScheme.primary.withOpacity(0.1);
      iconColor = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgIconColor,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
