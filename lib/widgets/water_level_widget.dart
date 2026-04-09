/// Water level widget — animated wave effect showing fill percentage.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gsyn/core/constants.dart';

class WaterLevelWidget extends StatefulWidget {
  final String title;
  final double percentage; // 0.0 - 1.0
  final String label;

  const WaterLevelWidget({
    super.key,
    required this.title,
    required this.percentage,
    this.label = '',
  });

  @override
  State<WaterLevelWidget> createState() => _WaterLevelWidgetState();
}

class _WaterLevelWidgetState extends State<WaterLevelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _WaterPainter(
                      percentage: widget.percentage.clamp(0, 1),
                      animValue: _controller.value,
                    ),
                    child: Center(
                      child: Text(
                        '${(widget.percentage * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double percentage;
  final double animValue;

  _WaterPainter({required this.percentage, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final r = min(size.width, size.height) / 2 - 4;
    final center = Offset(size.width / 2, size.height / 2);

    // Circle outline
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFF2D3F51)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Clip to circle
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: r - 1)),
    );

    // Water fill
    final waterY = center.dy + r - (percentage * r * 2);
    final path = Path();
    path.moveTo(center.dx - r, waterY);

    for (double x = -r; x <= r; x += 2) {
      final y = waterY + sin((x / r * 2 * pi) + (animValue * 2 * pi)) * 3;
      path.lineTo(center.dx + x, y);
    }
    path.lineTo(center.dx + r, center.dy + r);
    path.lineTo(center.dx - r, center.dy + r);
    path.close();

    final color = percentage > 0.8
        ? AppColors.zoneNormal
        : percentage > 0.3
        ? AppColors.primary
        : AppColors.danger;

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.7));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) =>
      old.percentage != percentage || old.animValue != animValue;
}
