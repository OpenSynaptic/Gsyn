/// Gauge widget — radial gauge with three-color arcs.
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:gsyn/core/constants.dart';

class GaugeWidget extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final String unit;
  final double warningValue;
  final double dangerValue;

  const GaugeWidget({
    super.key,
    required this.title,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.unit = '',
    required this.warningValue,
    required this.dangerValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: min,
                    maximum: max,
                    showLabels: true,
                    showTicks: true,
                    axisLabelStyle: const GaugeTextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    majorTickStyle: const MajorTickStyle(
                      length: 6,
                      thickness: 1.5,
                      color: AppColors.textSecondary,
                    ),
                    minorTickStyle: const MinorTickStyle(
                      length: 3,
                      thickness: 1,
                      color: Color(0xFF2D3F51),
                    ),
                    axisLineStyle: const AxisLineStyle(
                      thickness: 0.08,
                      thicknessUnit: GaugeSizeUnit.factor,
                      color: Color(0xFF1B2838),
                    ),
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: min,
                        endValue: warningValue,
                        color: AppColors.zoneNormal,
                        startWidth: 8,
                        endWidth: 8,
                      ),
                      GaugeRange(
                        startValue: warningValue,
                        endValue: dangerValue,
                        color: AppColors.zoneWarning,
                        startWidth: 8,
                        endWidth: 8,
                      ),
                      GaugeRange(
                        startValue: dangerValue,
                        endValue: max,
                        color: AppColors.zoneDanger,
                        startWidth: 8,
                        endWidth: 8,
                      ),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: value.clamp(min, max),
                        needleColor: AppColors.textPrimary,
                        needleLength: 0.7,
                        needleStartWidth: 0.5,
                        needleEndWidth: 2,
                        knobStyle: const KnobStyle(
                          knobRadius: 0.06,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Text(
                          '${value.toStringAsFixed(1)} $unit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getValueColor(),
                          ),
                        ),
                        angle: 90,
                        positionFactor: 0.75,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getValueColor() {
    if (value >= dangerValue) return AppColors.zoneDanger;
    if (value >= warningValue) return AppColors.zoneWarning;
    return AppColors.zoneNormal;
  }
}
