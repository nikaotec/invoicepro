import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_profile_provider.dart';
import 'business_settings_screen.dart';
import 'pricing_plan_screen.dart';
import 'currency_tax_settings_screen.dart';
import 'late_fees_settings_screen.dart';
import '../dashboard/cash_flow_dashboard_screen.dart';
import '../invoice/invoice_list_screen.dart';

// Settings state provider for automation settings
final autoRemindersProvider = StateProvider<bool>((ref) => true);
final lateFeesEnabledProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final businessProfile = ref.watch(businessProfileProvider);
    final autoReminders = ref.watch(autoRemindersProvider);
    final lateFeesEnabled = ref.watch(lateFeesEnabledProvider);

    final userName =
        authState.user?.displayName ??
        authState.user?.email?.split('@').first ??
        'User';
    final companyName = businessProfile.name;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101622)
          : const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    _buildProfileSection(
                      context,
                      isDark,
                      userName,
                      companyName,
                      businessProfile,
                    ),

                    const SizedBox(height: 32),

                    // General Section
                    _buildSectionHeader(context, isDark, 'General'),
                    const SizedBox(height: 12),
                    _buildGeneralSection(context, isDark),

                    const SizedBox(height: 24),

                    // Automation Section
                    _buildSectionHeader(context, isDark, 'Automation'),
                    const SizedBox(height: 12),
                    _buildAutomationSection(
                      context,
                      isDark,
                      autoReminders,
                      lateFeesEnabled,
                    ),

                    const SizedBox(height: 24),

                    // Support & Account Section
                    _buildSectionHeader(context, isDark, 'Support & Account'),
                    const SizedBox(height: 12),
                    _buildSupportSection(context, isDark),

                    const SizedBox(height: 24),

                    // Version Info
                    _buildVersionInfo(context, isDark),

                    const SizedBox(height: 100), // Space for bottom nav
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF101622) : const Color(0xFFF9FAFB))
            .withOpacity(0.9),
      ),
      child: Column(
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CashFlowDashboardScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.chevron_left, color: const Color(0xFF135BEC)),
                label: const Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Color(0xFF135BEC),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Settings',
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

  Widget _buildProfileSection(
    BuildContext context,
    bool isDark,
    String userName,
    String companyName,
    businessProfile,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
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
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.grey[600]! : Colors.white,
                    width: 2,
                  ),
                ),
                child: businessProfile.logoBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          businessProfile.logoBytes!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          userName.isNotEmpty
                              ? userName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 512,
                      maxHeight: 512,
                      imageQuality: 85,
                    );
                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      ref
                          .read(businessProfileProvider.notifier)
                          .updateProfile(logoBytes: bytes);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile picture updated'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF135BEC),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Name and Company
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // QR Code Button
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            color: const Color(0xFF135BEC),
            onPressed: () {
              _showQRCodeDialog(context, isDark, userName, companyName);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context, bool isDark) {
    final businessProfile = ref.watch(businessProfileProvider);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
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
      child: Column(
        children: [
          // Business Profile
          _buildSettingsItem(
            context,
            isDark,
            icon: Icons.storefront,
            iconColor: const Color(0xFF135BEC),
            title: 'Business Profile',
            subtitle: 'Logo, address, tax ID',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BusinessSettingsScreen(),
                ),
              );
            },
            showDivider: true,
          ),
          // Payment Methods
          _buildSettingsItem(
            context,
            isDark,
            icon: Icons.credit_card,
            iconColor: Colors.green,
            title: 'Payment Methods',
            subtitle: 'Stripe, PayPal, Bank',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PricingPlanScreen()),
              );
            },
            showDivider: true,
          ),
          // Currency & Tax
          _buildSettingsItem(
            context,
            isDark,
            icon: Icons.currency_exchange,
            iconColor: Colors.purple,
            title: 'Currency & Tax Rates',
            subtitle: null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${businessProfile.currency} (\$)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CurrencyTaxSettingsScreen(),
                ),
              );
            },
          ),
          // Theme Settings
          _buildSettingsItem(
            context,
            isDark,
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            iconColor: Colors.amber,
            title: 'Theme',
            subtitle: _getThemeModeText(ref.watch(themeProvider)),
            onTap: () {
              _showThemeSelector(context, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationSection(
    BuildContext context,
    bool isDark,
    bool autoReminders,
    bool lateFeesEnabled,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
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
      child: Column(
        children: [
          // Auto-Reminders
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Reminders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Send 3 days before due',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: autoReminders,
                  onChanged: (value) {
                    ref.read(autoRemindersProvider.notifier).state = value;
                  },
                  activeColor: const Color(0xFF135BEC),
                ),
              ],
            ),
          ),
          // Late Fees
          _buildSettingsItem(
            context,
            isDark,
            icon: Icons.percent,
            iconColor: Colors.red,
            title: 'Late Fees',
            subtitle: null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lateFeesEnabled ? 'On' : 'Off',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LateFeesSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
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
      child: Column(
        children: [
          // Help Center
          _buildSettingsItem(
            context,
            isDark,
            icon: Icons.help,
            iconColor: isDark ? Colors.grey[400]! : Colors.grey[600]!,
            title: 'Help Center',
            subtitle: null,
            trailing: Icon(
              Icons.open_in_new,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            onTap: () {
              _showHelpCenter(context, isDark);
            },
            showDivider: true,
          ),
          // Log Out
          InkWell(
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && mounted) {
                await ref.read(authProvider.notifier).signOut();
                // Navigation will be handled by main.dart auth state listener
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.transparent),
              child: Center(
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    bool showDivider = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null)
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context, bool isDark) {
    return Center(
      child: Text(
        'Version 2.4.0 (Build 302)',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1F2937) : Colors.white).withOpacity(
          0.95,
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                isDark,
                icon: Icons.dashboard,
                label: 'Home',
                isSelected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CashFlowDashboardScreen(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                context,
                isDark,
                icon: Icons.receipt_long,
                label: 'Invoices',
                isSelected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InvoiceListScreen(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                context,
                isDark,
                icon: Icons.settings,
                label: 'Settings',
                isSelected: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFF135BEC)
                : (isDark ? Colors.grey[400]! : Colors.grey[600]!),
            size: 24,
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
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeSelector(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Theme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildThemeOption(
              context,
              isDark,
              title: 'Light',
              mode: ThemeMode.light,
              icon: Icons.light_mode,
            ),
            _buildThemeOption(
              context,
              isDark,
              title: 'Dark',
              mode: ThemeMode.dark,
              icon: Icons.dark_mode,
            ),
            _buildThemeOption(
              context,
              isDark,
              title: 'System',
              mode: ThemeMode.system,
              icon: Icons.brightness_auto,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    bool isDark, {
    required String title,
    required ThemeMode mode,
    required IconData icon,
  }) {
    final currentMode = ref.watch(themeProvider);
    final isSelected = currentMode == mode;

    return InkWell(
      onTap: () {
        ref.read(themeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF135BEC)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF135BEC)
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, color: const Color(0xFF135BEC)),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog(
    BuildContext context,
    bool isDark,
    String userName,
    String companyName,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Business QR Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              // QR Code Placeholder
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 80,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QR Code',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                companyName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement share/download QR code
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QR Code sharing coming soon'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135BEC),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpCenter(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Help Center',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                _buildHelpItem(
                  context,
                  isDark,
                  icon: Icons.book,
                  title: 'Getting Started',
                  subtitle: 'Learn how to create your first invoice',
                ),
                _buildHelpItem(
                  context,
                  isDark,
                  icon: Icons.payment,
                  title: 'Payment Methods',
                  subtitle: 'Set up and manage payment options',
                ),
                _buildHelpItem(
                  context,
                  isDark,
                  icon: Icons.people,
                  title: 'Managing Clients',
                  subtitle: 'Add and organize your clients',
                ),
                _buildHelpItem(
                  context,
                  isDark,
                  icon: Icons.settings,
                  title: 'Settings & Preferences',
                  subtitle: 'Customize your app experience',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135BEC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: const Color(0xFF135BEC)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need more help?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'support@invoicepro.com',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to specific help article
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Help article: $title')));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101622) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF135BEC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF135BEC), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
