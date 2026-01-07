import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/invoice_model.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/dashboard/recent_activity_item.dart';
import '../invoice/new_invoice_screen.dart';
import '../clients/clients_list_screen.dart';
import '../invoice/invoice_list_screen.dart';
import '../invoice/invoice_detail_screen.dart';
import '../settings/settings_screen.dart';

class CashFlowDashboardScreen extends ConsumerStatefulWidget {
  const CashFlowDashboardScreen({super.key});

  @override
  ConsumerState<CashFlowDashboardScreen> createState() =>
      _CashFlowDashboardScreenState();
}

class _CashFlowDashboardScreenState
    extends ConsumerState<CashFlowDashboardScreen> {
  int _currentBottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final invoiceState = ref.watch(invoiceProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    // Get user name from auth or default
    final userName = authState.user?.displayName ?? 
                    authState.user?.email?.split('@').first ?? 
                    'User';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header / Top App Bar
            _buildHeader(context, isDark, userName),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Balance
                    _buildTotalBalance(context, isDark, statsAsync),

                    // Stats Cards (Horizontal Scroll)
                    _buildStatsCards(context, isDark, statsAsync),

                    // Quick Actions Chips
                    _buildQuickActions(context, isDark),

                    // Recent Activity List
                    _buildRecentActivity(context, isDark, invoiceState.invoices),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNavigation(context, isDark),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8))
            .withOpacity(0.95),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User Profile
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Text(
                      userName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF101622) : Colors.white,
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
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Notifications Button
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2233) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  size: 24,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalance(
    BuildContext context,
    bool isDark,
    AsyncValue<Map<String, dynamic>> statsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          statsAsync.when(
            data: (stats) {
              final totalBalance = stats['totalRevenue'] ?? 0.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                        .format(totalBalance),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+2.4%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text(
              '\$0.00',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    bool isDark,
    AsyncValue<Map<String, dynamic>> statsAsync,
  ) {
    return statsAsync.when(
      data: (stats) {
        final dueToday = stats['dueToday'] ?? 0.0;
        final overdue = stats['overdue'] ?? 0.0;
        final received = stats['received'] ?? 0.0;

        return Container(
          height: 120,
          margin: const EdgeInsets.only(top: 24),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              StatCard(
                icon: Icons.calendar_today,
                title: 'Due Today',
                amount: dueToday,
                iconColor: isDark ? Colors.grey[300]! : Colors.grey[600]!,
                backgroundColor: isDark ? const Color(0xFF1A2233) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 16),
              StatCard(
                icon: Icons.error,
                title: 'Overdue',
                amount: overdue,
                iconColor: Colors.red,
                backgroundColor: isDark ? const Color(0xFF1A2233) : Colors.white,
                textColor: Colors.red,
                isError: true,
              ),
              const SizedBox(width: 16),
              StatCard(
                icon: Icons.check_circle,
                title: 'Received',
                amount: received,
                iconColor: Colors.white,
                backgroundColor: const Color(0xFF135BEC),
                textColor: Colors.white,
                isPrimary: true,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(height: 120),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildActionChip(
              context: context,
              icon: Icons.add,
              label: 'New Invoice',
              isPrimary: true,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NewInvoiceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildActionChip(
              context: context,
              icon: Icons.person_add,
              label: 'Add Client',
              isPrimary: false,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClientsListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildActionChip(
              context: context,
              icon: Icons.send,
              label: 'Reminder',
              isPrimary: false,
              isDark: isDark,
              onTap: () {
                // TODO: Implement reminder functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder feature coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF135BEC)
              : (isDark ? const Color(0xFF1A2233) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: isPrimary
              ? null
              : Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? Colors.grey[300] : Colors.grey[700]),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    bool isDark,
    List<Invoice> invoices,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InvoiceListScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF135BEC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (invoices.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2233) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ...invoices.take(4).map((invoice) {
              return RecentActivityItem(
                invoice: invoice,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id),
                    ),
                  );
                },
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2233) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                isSelected: _currentBottomNavIndex == 0,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _currentBottomNavIndex = 0;
                  });
                },
              ),
              _buildNavItem(
                icon: Icons.description,
                label: 'Invoices',
                isSelected: _currentBottomNavIndex == 1,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _currentBottomNavIndex = 1;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InvoiceListScreen(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.group,
                label: 'Clients',
                isSelected: _currentBottomNavIndex == 2,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _currentBottomNavIndex = 2;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClientsListScreen(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.settings,
                label: 'Settings',
                isSelected: _currentBottomNavIndex == 3,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _currentBottomNavIndex = 3;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color(0xFF135BEC)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              fill: isSelected ? 1.0 : 0.0,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF135BEC)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

