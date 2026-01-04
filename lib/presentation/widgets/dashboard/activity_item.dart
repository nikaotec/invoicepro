import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Activity item component for recent activity list
class ActivityItem extends StatelessWidget {
  final String? logoPath;
  final String? initials;
  final Color? initialsBackgroundColor;
  final Color? initialsTextColor;
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final bool isPaid;
  final VoidCallback? onTap;

  const ActivityItem({
    super.key,
    this.logoPath,
    this.initials,
    this.initialsBackgroundColor,
    this.initialsTextColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.isPaid,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar/Logo
              _buildAvatar(context),
              const SizedBox(width: 16),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount and status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (logoPath != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withOpacity(isDark ? 0.2 : 0.5),
            width: 1,
          ),
          image: DecorationImage(
            image: AssetImage(logoPath!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Initials fallback
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color:
            initialsBackgroundColor ??
            (isDark
                ? AppColors.warning.withOpacity(0.2)
                : AppColors.warningLight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              (initialsBackgroundColor ??
                      (isDark
                          ? AppColors.warning.withOpacity(0.2)
                          : AppColors.warningLight))
                  .withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          initials ?? '??',
          style: TextStyle(
            color: initialsTextColor ?? AppColors.warning,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statusColor = isPaid ? AppColors.success : AppColors.warning;
    final backgroundColor = isPaid
        ? (isDark ? AppColors.success.withOpacity(0.2) : AppColors.successLight)
        : (isDark
              ? AppColors.warning.withOpacity(0.2)
              : AppColors.warningLight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9999),
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
            status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
