import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import 'package:fl_chart/fl_chart.dart';

/// Dashboard home screen with financial overview
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: AppDimensions.spacingSm),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(
            ResponsiveLayout.getHorizontalPadding(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Financial summary cards
              _buildSummaryCards(context),

              const SizedBox(height: AppDimensions.spacingXl),

              // Revenue chart
              _buildRevenueChart(context),

              const SizedBox(height: AppDimensions.spacingXl),

              // Recent invoices
              _buildRecentInvoices(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final gridColumns = ResponsiveLayout.getGridColumns(context);

    return GridView.count(
      crossAxisCount: gridColumns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppDimensions.spacingLg,
      mainAxisSpacing: AppDimensions.spacingLg,
      childAspectRatio: 1.8,
      children: [
        _SummaryCard(
          title: 'Total Revenue',
          value: CurrencyFormatter.formatCurrency(45250.00),
          change: '+12.5%',
          isPositive: true,
          icon: Icons.trending_up,
          color: AppColors.success,
        ),
        _SummaryCard(
          title: 'Pending',
          value: CurrencyFormatter.formatCurrency(8750.00),
          subtitle: '12 invoices',
          icon: Icons.schedule,
          color: AppColors.warning,
        ),
        _SummaryCard(
          title: 'Overdue',
          value: CurrencyFormatter.formatCurrency(2100.00),
          subtitle: '3 invoices',
          icon: Icons.warning_outlined,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenue Trend', style: AppTextStyles.headingMedium),
            const SizedBox(height: AppDimensions.spacingMd),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.borderLight,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            CurrencyFormatter.formatCompact(value),
                            style: AppTextStyles.caption,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final labels = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < labels.length) {
                            return Text(
                              labels[value.toInt()],
                              style: AppTextStyles.caption,
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 15000),
                        FlSpot(1, 22000),
                        FlSpot(2, 18000),
                        FlSpot(3, 28000),
                        FlSpot(4, 35000),
                        FlSpot(5, 45000),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Invoices', style: AppTextStyles.headingMedium),
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Card(
          child: Column(
            children: [
              _buildInvoiceItem(
                'INV-00123',
                'Acme Corp',
                '\$1,250.00',
                'Paid',
                true,
              ),
              const Divider(height: 1),
              _buildInvoiceItem(
                'INV-00124',
                'TechStart Inc',
                '\$3,500.00',
                'Pending',
                false,
              ),
              const Divider(height: 1),
              _buildInvoiceItem(
                'INV-00125',
                'Design Studio',
                '\$850.00',
                'Paid',
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceItem(
    String number,
    String client,
    String amount,
    String status,
    bool isPaid,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingSm,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPaid ? AppColors.successLight : AppColors.warningLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Icon(
          isPaid ? Icons.check_circle : Icons.schedule,
          color: isPaid ? AppColors.success : AppColors.warning,
          size: AppDimensions.iconMd,
        ),
      ),
      title: Text(number, style: AppTextStyles.labelMedium),
      subtitle: Text(client, style: AppTextStyles.bodySmall),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amount, style: AppTextStyles.labelMedium),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingSm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isPaid ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              status,
              style: AppTextStyles.caption.copyWith(
                color: isPaid ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String? change;
  final bool? isPositive;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.change,
    this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.bodySmall),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingSm),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(icon, color: color, size: AppDimensions.iconMd),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.numberMedium),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.caption)
                else if (change != null)
                  Text(
                    change!,
                    style: AppTextStyles.caption.copyWith(
                      color: isPositive == true
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
