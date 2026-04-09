/// Real-time line chart widget — auto-scrolling time series.
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gsyn/core/constants.dart';

class RealtimeLineChart extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final double? warningThreshold;
  final double? dangerThreshold;
  final String unit;
  final Color lineColor;

  const RealtimeLineChart({
    super.key,
    required this.title,
    required this.spots,
    this.warningThreshold,
    this.dangerThreshold,
    this.unit = '',
    this.lineColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: spots.isEmpty
                  ? const Center(
                      child: Text(
                        'No data',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : LineChart(_buildChartData()),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    final extraLines = <HorizontalLine>[];
    if (warningThreshold != null) {
      extraLines.add(
        HorizontalLine(
          y: warningThreshold!,
          color: AppColors.warning.withValues(alpha: 0.6),
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      );
    }
    if (dangerThreshold != null) {
      extraLines.add(
        HorizontalLine(
          y: dangerThreshold!,
          color: AppColors.danger.withValues(alpha: 0.6),
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      );
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _calcInterval(),
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: Color(0xFF2D3F51), strokeWidth: 0.5),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (val, _) => Text(
              val.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(horizontalLines: extraLines),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: lineColor,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withValues(alpha: 0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots
              .map(
                (s) => LineTooltipItem(
                  '${s.y.toStringAsFixed(1)} $unit',
                  TextStyle(color: lineColor, fontSize: 12),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  double _calcInterval() {
    if (spots.isEmpty) return 10;
    double min = spots.first.y, max = spots.first.y;
    for (final s in spots) {
      if (s.y < min) min = s.y;
      if (s.y > max) max = s.y;
    }
    final range = max - min;
    if (range < 1) return 1;
    return (range / 5).ceilToDouble();
  }
}
