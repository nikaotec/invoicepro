import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Modern balance card with gradient chart
class ModernBalanceCard extends StatelessWidget {
  final String balance;
  final String changePercentage;
  final bool isPositiveChange;

  const ModernBalanceCard({
    super.key,
    required this.balance,
    required this.changePercentage,
    this.isPositiveChange = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with balance and change indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      balance,
                      style: TextStyle(
                        fontSize: 40,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        height: 1.0,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPositiveChange
                        ? (isDark
                              ? AppColors.success.withOpacity(0.2)
                              : AppColors.successLight)
                        : (isDark
                              ? AppColors.error.withOpacity(0.2)
                              : AppColors.errorLight),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: isPositiveChange
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveChange
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: isPositiveChange
                            ? AppColors.success
                            : AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        changePercentage,
                        style: TextStyle(
                          color: isPositiveChange
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chart
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 160),
                  painter: _BalanceChartPainter(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 24,
                  right: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map(
                          (day) => Text(
                            day,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.6),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the balance chart
class _BalanceChartPainter extends CustomPainter {
  final Color color;

  _BalanceChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height - 32; // Reserve space for labels

    // Define the curve points (matching the HTML design)
    final points = [
      Offset(0, height * 0.7),
      Offset(width * 0.333, height * 0.3),
      Offset(width * 0.666, height * 0.5),
      Offset(width, height * 0.2),
    ];

    // Create the curve path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      // Calculate control points for smooth curve
      final controlPoint1 = Offset(
        current.dx + (next.dx - current.dx) * 0.4,
        current.dy,
      );
      final controlPoint2 = Offset(
        current.dx + (next.dx - current.dx) * 0.6,
        next.dy,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        next.dx,
        next.dy,
      );
    }

    // Draw gradient fill
    final gradientPath = Path.from(path);
    gradientPath.lineTo(width, height);
    gradientPath.lineTo(0, height);
    gradientPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(gradientPath, gradientPaint);

    // Draw the line
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
