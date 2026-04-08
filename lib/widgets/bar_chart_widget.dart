/// Bar chart widget (supports grouped and stacked).
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';

class BarChartWidget extends StatelessWidget {
  final String title;
  final List<String> labels;
  final List<double> values;
  final Color barColor;

  const BarChartWidget({
    super.key,
    required this.title,
    required this.labels,
    required this.values,
    this.barColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Expanded(
              child: values.isEmpty
                  ? const Center(child: Text('No data', style: TextStyle(color: AppColors.textSecondary)))
                  : BarChart(
                      BarChartData(
                        barGroups: List.generate(values.length, (i) {
                          return BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: values[i],
                              color: barColor,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ]);
                        }),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                final i = val.toInt();
                                if (i >= 0 && i < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(labels[i],
                                        style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (val, _) => Text(val.toStringAsFixed(0),
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFF2D3F51), strokeWidth: 0.5),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

