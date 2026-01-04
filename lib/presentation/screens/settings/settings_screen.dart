import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import 'business_settings_screen.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSection('Business Profile'),
          _buildListTile(
            icon: Icons.business,
            title: 'Company Information',
            subtitle: 'Name, logo, and contact details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusinessSettingsScreen(),
                ),
              );
            },
          ),
          _buildListTile(
            icon: Icons.receipt,
            title: 'Invoice Settings',
            subtitle: 'Templates and numbering',
            onTap: () {},
          ),

          const Divider(height: 32),

          _buildSection('Preferences'),
          _buildListTile(
            icon: Icons.attach_money,
            title: 'Currency & Tax',
            subtitle: 'Default currency and tax rate',
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.payment,
            title: 'Payment Methods',
            subtitle: 'Configure payment options',
            onTap: () {},
          ),

          const Divider(height: 32),

          _buildSection('Data & Sync'),
          _buildListTile(
            icon: Icons.cloud_sync,
            title: 'Sync',
            subtitle: 'Last synced: 5 minutes ago',
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.backup,
            title: 'Backup & Restore',
            subtitle: 'Manage your data backup',
            onTap: () {},
          ),

          const Divider(height: 32),

          _buildSection('About'),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingXl,
        AppDimensions.spacingLg,
        AppDimensions.spacingSm,
      ),
      child: Text(title.toUpperCase(), style: AppTextStyles.overline),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingSm),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Icon(icon, color: AppColors.primary, size: AppDimensions.iconMd),
      ),
      title: Text(title, style: AppTextStyles.labelMedium),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTextStyles.bodySmall)
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
