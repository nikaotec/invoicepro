import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/invoice_model.dart' as ui_model;
import '../../providers/invoice_provider.dart';
import '../../providers/auth_provider.dart';
import 'new_invoice_screen.dart';
import 'invoice_detail_screen.dart';
import '../dashboard/cash_flow_dashboard_screen.dart';
import '../clients/clients_list_screen.dart';
import '../settings/settings_screen.dart';

// Filter state provider
final invoiceFilterProvider = StateProvider<InvoiceFilter>(
  (ref) => InvoiceFilter.all,
);

enum InvoiceFilter { all, pending, overdue, paid }

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  int _currentBottomNavIndex = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final invoiceState = ref.watch(invoiceProvider);
    final filter = ref.watch(invoiceFilterProvider);

    // Get user name
    final userName =
        authState.user?.displayName ??
        authState.user?.email?.split('@').first ??
        'User';

    // Filter invoices
    final filteredInvoices = _filterInvoices(invoiceState.invoices, filter);

    // Calculate stats
    final stats = _calculateStats(invoiceState.invoices);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101622)
          : const Color(0xFFF6F6F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark, userName),

            // Stats Section
            _buildStatsSection(context, isDark, stats),

            // Filter Chips
            _buildFilterChips(context, isDark, filter, stats),

            // Invoice List
            Expanded(
              child: filteredInvoices.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredInvoices.length,
                      itemBuilder: (context, index) {
                        return _buildInvoiceCard(
                          context,
                          isDark,
                          filteredInvoices[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewInvoiceScreen()),
          );
        },
        backgroundColor: const Color(0xFF135BEC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Invoice',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNavigation(context, isDark),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, String userName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8))
            .withOpacity(0.9),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Avatar
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
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
                          color: isDark
                              ? const Color(0xFF101622)
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Title
          Text(
            'Invoices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          // Search Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2233) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
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
            child: IconButton(
              icon: Icon(
                Icons.search,
                size: 20,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
              onPressed: () {
                // TODO: Implement search
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> stats,
  ) {
    final totalOutstanding = stats['totalOutstanding'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF135BEC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF135BEC).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Outstanding',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormat.currency(
                  symbol: '\$',
                  decimalDigits: 2,
                ).format(totalOutstanding),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '+12%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'vs last month',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    bool isDark,
    InvoiceFilter currentFilter,
    Map<String, dynamic> stats,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              context: context,
              label: 'All',
              isSelected: currentFilter == InvoiceFilter.all,
              isDark: isDark,
              onTap: () {
                ref.read(invoiceFilterProvider.notifier).state =
                    InvoiceFilter.all;
              },
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              context: context,
              label: 'Pending',
              count: stats['pendingCount'] ?? 0,
              isSelected: currentFilter == InvoiceFilter.pending,
              isDark: isDark,
              onTap: () {
                ref.read(invoiceFilterProvider.notifier).state =
                    InvoiceFilter.pending;
              },
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              context: context,
              label: 'Overdue',
              count: stats['overdueCount'] ?? 0,
              isSelected: currentFilter == InvoiceFilter.overdue,
              isDark: isDark,
              isError: true,
              onTap: () {
                ref.read(invoiceFilterProvider.notifier).state =
                    InvoiceFilter.overdue;
              },
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              context: context,
              label: 'Paid',
              isSelected: currentFilter == InvoiceFilter.paid,
              isDark: isDark,
              onTap: () {
                ref.read(invoiceFilterProvider.notifier).state =
                    InvoiceFilter.paid;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    int? count,
    required bool isSelected,
    required bool isDark,
    bool isError = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black87)
              : (isDark ? const Color(0xFF1A2233) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.black87 : Colors.white)
                      : (isDark ? Colors.grey[300] : Colors.grey[600]),
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isError && !isSelected
                        ? Colors.red
                        : (isSelected
                              ? (isDark ? Colors.black87 : Colors.white)
                              : (isDark ? Colors.grey[400] : Colors.grey[500])),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    bool isDark,
    ui_model.Invoice invoice,
  ) {
    final isPaid = invoice.status == ui_model.InvoiceStatus.paid;
    final isOverdue = invoice.status == ui_model.InvoiceStatus.overdue;

    Color statusColor;
    Color statusBgColor;
    String statusLabel;
    String dateText;

    if (isPaid) {
      statusColor = isDark ? Colors.green[400]! : Colors.green[600]!;
      statusBgColor = isDark
          ? Colors.green[900]!.withOpacity(0.2)
          : Colors.green[50]!;
      statusLabel = 'Paid';
      dateText = 'Paid ${DateFormat('MMM d').format(invoice.date)}';
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusBgColor = isDark
          ? Colors.red[900]!.withOpacity(0.2)
          : Colors.red[50]!;
      statusLabel = 'Overdue';
      dateText = 'Due ${DateFormat('MMM d').format(invoice.dueDate)}';
    } else {
      statusColor = isDark ? Colors.orange[400]! : Colors.orange[600]!;
      statusBgColor = isDark
          ? Colors.orange[900]!.withOpacity(0.2)
          : Colors.orange[50]!;
      statusLabel = 'Pending';
      dateText = 'Due ${DateFormat('MMM d').format(invoice.dueDate)}';
    }

    final initials = _getInitials(invoice.clientName);
    final avatarColor = _getAvatarColor(invoice.clientName);
    final avatarBgColor = _getAvatarBackgroundColor(invoice.clientName, isDark);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151B26) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          invoice.clientName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: 2,
                        ).format(invoice.amount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isOverdue
                              ? (isDark ? Colors.red[400] : Colors.red[600])
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.number,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateText,
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue
                                  ? (isDark ? Colors.red[400] : Colors.red[500])
                                  : (isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[400]),
                              fontWeight: isOverdue
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No invoices found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first invoice to get started',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101622) : Colors.white,
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CashFlowDashboardScreen(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.receipt_long,
                label: 'Invoices',
                isSelected: _currentBottomNavIndex == 1,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _currentBottomNavIndex = 1;
                  });
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
              size: 26,
              color: isSelected
                  ? const Color(0xFF135BEC)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  List<ui_model.Invoice> _filterInvoices(
    List<ui_model.Invoice> invoices,
    InvoiceFilter filter,
  ) {
    switch (filter) {
      case InvoiceFilter.all:
        return invoices;
      case InvoiceFilter.pending:
        return invoices
            .where((i) => i.status == ui_model.InvoiceStatus.pending)
            .toList();
      case InvoiceFilter.overdue:
        return invoices
            .where((i) => i.status == ui_model.InvoiceStatus.overdue)
            .toList();
      case InvoiceFilter.paid:
        return invoices
            .where((i) => i.status == ui_model.InvoiceStatus.paid)
            .toList();
    }
  }

  Map<String, dynamic> _calculateStats(List<ui_model.Invoice> invoices) {
    double totalOutstanding = 0.0;
    int pendingCount = 0;
    int overdueCount = 0;

    for (final invoice in invoices) {
      if (invoice.status == ui_model.InvoiceStatus.pending ||
          invoice.status == ui_model.InvoiceStatus.overdue) {
        totalOutstanding += invoice.amount;
      }
      if (invoice.status == ui_model.InvoiceStatus.pending) {
        pendingCount++;
      }
      if (invoice.status == ui_model.InvoiceStatus.overdue) {
        overdueCount++;
      }
    }

    return {
      'totalOutstanding': totalOutstanding,
      'pendingCount': pendingCount,
      'overdueCount': overdueCount,
    };
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF0EA5E9), // Sky
      const Color(0xFF8B5CF6), // Violet
    ];
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }

  Color _getAvatarBackgroundColor(String name, bool isDark) {
    final color = _getAvatarColor(name);
    return isDark ? color.withOpacity(0.3) : color.withOpacity(0.1);
  }
}
