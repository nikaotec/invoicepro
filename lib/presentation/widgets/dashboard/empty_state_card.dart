import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class EmptyStateCard extends StatelessWidget {
  final VoidCallback onCreateInvoice;

  const EmptyStateCard({super.key, required this.onCreateInvoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24), // rounded-3xl
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Graphic with glow effect
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 192, // w-48
                height: 192, // h-48
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.05),
                ),
              ),
              // SVG Graphic (CustomPaint matching the HTML SVG)
              CustomPaint(
                size: const Size(120, 120),
                painter: _AnalysisGraphicPainter(
                  color: theme.colorScheme.primary,
                  surfaceColor: isDark
                      ? theme.cardColor
                      : theme.colorScheme.surface,
                  lineColor: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            'Bem-vindo ao Invoicely Pro!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'Crie sua primeira fatura para começar a gerenciar suas finanças.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // CTA Button
          SizedBox(
            width: 200, // max-w-xs approx
            height: 48,
            child: ElevatedButton(
              onPressed: onCreateInvoice,
              style:
                  ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // rounded-xl
                    ),
                    padding: EdgeInsets.zero,
                  ).copyWith(
                    shadowColor: WidgetStateProperty.all(
                      theme.colorScheme.primary.withOpacity(0.4),
                    ),
                    elevation: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) return 0;
                      return 10; // shadow-glow effect estimation
                    }),
                  ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Criar Fatura',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisGraphicPainter extends CustomPainter {
  final Color color;
  final Color surfaceColor;
  final Color lineColor;

  _AnalysisGraphicPainter({
    required this.color,
    required this.surfaceColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintStroke = Paint()
      ..color = lineColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;

    final paintStrokeSolid = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Dashed Circle
    final radius = 48.0;
    final center = Offset(size.width / 2, size.height / 2);
    _drawDashedCircle(
      canvas,
      center,
      radius,
      Paint()
        ..color = lineColor.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Rect
    final rect = Rect.fromLTWH(42, 32, 36, 48);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paintFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paintStrokeSolid,
    );

    // Lines
    canvas.drawLine(const Offset(50, 44), const Offset(70, 44), paintStroke);
    canvas.drawLine(const Offset(50, 52), const Offset(70, 52), paintStroke);
    canvas.drawLine(const Offset(50, 60), const Offset(62, 60), paintStroke);

    // Magnifying Glass group (translate 68, 68)
    canvas.save();
    canvas.translate(68, 68);

    // Glass
    canvas.drawCircle(const Offset(12, 12), 14, paintFill);
    canvas.drawCircle(const Offset(12, 12), 14, paintStrokeSolid);

    // Handle
    // M12 7V17M7 12H17
    canvas.drawLine(
      const Offset(12, 7),
      const Offset(12, 17),
      paintStrokeSolid,
    );
    canvas.drawLine(
      const Offset(7, 12),
      const Offset(17, 12),
      paintStrokeSolid,
    );

    canvas.restore();
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const double dashWidth = 8;
    const double dashSpace = 8;
    double startAngle = 0;
    final circumference = 2 * 3.14159 * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final anglePerDash = (2 * 3.14159) / dashCount;
    final dashAngle = (dashWidth / circumference) * 2 * 3.14159;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
      startAngle += anglePerDash;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
