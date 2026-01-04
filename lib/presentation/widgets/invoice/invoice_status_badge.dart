import 'package:flutter/material.dart';
import '../../../domain/entities/invoice.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Badge showing invoice status with color coding
class InvoiceStatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  final bool small;

  const InvoiceStatusBadge({
    super.key,
    required this.status,
    this.small = false,
  });

  Color _getColor(BuildContext context) {
    switch (status) {
      case InvoiceStatus.paid:
        return AppColors.statusPaid;
      case InvoiceStatus.sent:
        return AppColors.statusPending;
      case InvoiceStatus.overdue:
        return AppColors.statusOverdue;
      case InvoiceStatus.draft:
        return AppColors.statusDraft;
      case InvoiceStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (status) {
      case InvoiceStatus.paid:
        return isDark
            ? AppColors.statusPaid.withOpacity(0.2)
            : AppColors.successLight;
      case InvoiceStatus.sent:
        return isDark
            ? AppColors.statusPending.withOpacity(0.2)
            : AppColors.warningLight;
      case InvoiceStatus.overdue:
        return isDark
            ? AppColors.statusOverdue.withOpacity(0.2)
            : AppColors.errorLight;
      case InvoiceStatus.draft:
      case InvoiceStatus.cancelled:
        return isDark
            ? Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : AppColors.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppDimensions.spacingSm : AppDimensions.spacingMd,
        vertical: small ? AppDimensions.spacing2xs : AppDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: (small ? theme.textTheme.bodySmall : theme.textTheme.labelSmall)
            ?.copyWith(
              color: _getColor(context),
              fontWeight: FontWeight.w600,
              fontSize: small
                  ? 12
                  : 11, // Match AppTextStyles.caption / labelSmall approx
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
