/// Pie chart widget — device type distribution.
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';

class PieChartWidget extends StatelessWidget {
  final String title;
  final Map<String, double> data;

  const PieChartWidget({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('No data', style: TextStyle(color: AppColors.textSecondary)))
                  : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: PieChart(PieChartData(
                            sections: List.generate(entries.length, (i) {
                              return PieChartSectionData(
                                value: entries[i].value,
                                color: AppColors.chartPalette[i % AppColors.chartPalette.length],
                                title: '${entries[i].value.toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                radius: 50,
                              );
                            }),
                            centerSpaceRadius: 30,
                            sectionsSpace: 2,
                          )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(entries.length, (i) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: AppColors.chartPalette[i % AppColors.chartPalette.length],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(entries[i].key,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

