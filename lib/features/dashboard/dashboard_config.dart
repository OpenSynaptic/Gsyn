/// Dashboard card visibility configuration — provider + persistence.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardCardConfig {
  final bool kpiDevices;
  final bool kpiOnlineRate;
  final bool kpiAlerts;
  final bool kpiThroughput;
  final bool chartTemp;
  final bool chartHumidity;
  final bool gaugesRow1;   // Temperature + Pressure
  final bool gaugesRow2;   // Liquid Level + Humidity
  final bool barChart;
  final bool pieChart;

  const DashboardCardConfig({
    this.kpiDevices    = true,
    this.kpiOnlineRate = true,
    this.kpiAlerts     = true,
    this.kpiThroughput = true,
    this.chartTemp     = true,
    this.chartHumidity = true,
    this.gaugesRow1    = true,
    this.gaugesRow2    = true,
    this.barChart      = true,
    this.pieChart      = true,
  });

  DashboardCardConfig copyWith({
    bool? kpiDevices, bool? kpiOnlineRate, bool? kpiAlerts, bool? kpiThroughput,
    bool? chartTemp,  bool? chartHumidity, bool? gaugesRow1,  bool? gaugesRow2,
    bool? barChart,   bool? pieChart,
  }) =>
      DashboardCardConfig(
        kpiDevices:    kpiDevices    ?? this.kpiDevices,
        kpiOnlineRate: kpiOnlineRate ?? this.kpiOnlineRate,
        kpiAlerts:     kpiAlerts     ?? this.kpiAlerts,
        kpiThroughput: kpiThroughput ?? this.kpiThroughput,
        chartTemp:     chartTemp     ?? this.chartTemp,
        chartHumidity: chartHumidity ?? this.chartHumidity,
        gaugesRow1:    gaugesRow1    ?? this.gaugesRow1,
        gaugesRow2:    gaugesRow2    ?? this.gaugesRow2,
        barChart:      barChart      ?? this.barChart,
        pieChart:      pieChart      ?? this.pieChart,
      );
}

class DashboardConfigNotifier extends StateNotifier<DashboardCardConfig> {
  DashboardConfigNotifier() : super(const DashboardCardConfig());

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    state = DashboardCardConfig(
      kpiDevices:    p.getBool('card_kpi_devices')    ?? true,
      kpiOnlineRate: p.getBool('card_kpi_online_rate') ?? true,
      kpiAlerts:     p.getBool('card_kpi_alerts')     ?? true,
      kpiThroughput: p.getBool('card_kpi_throughput') ?? true,
      chartTemp:     p.getBool('card_chart_temp')     ?? true,
      chartHumidity: p.getBool('card_chart_hum')      ?? true,
      gaugesRow1:    p.getBool('card_gauges_row1')    ?? true,
      gaugesRow2:    p.getBool('card_gauges_row2')    ?? true,
      barChart:      p.getBool('card_bar_chart')      ?? true,
      pieChart:      p.getBool('card_pie_chart')      ?? true,
    );
  }

  Future<void> save(DashboardCardConfig config) async {
    state = config;
    final p = await SharedPreferences.getInstance();
    await p.setBool('card_kpi_devices',    config.kpiDevices);
    await p.setBool('card_kpi_online_rate', config.kpiOnlineRate);
    await p.setBool('card_kpi_alerts',     config.kpiAlerts);
    await p.setBool('card_kpi_throughput', config.kpiThroughput);
    await p.setBool('card_chart_temp',     config.chartTemp);
    await p.setBool('card_chart_hum',      config.chartHumidity);
    await p.setBool('card_gauges_row1',    config.gaugesRow1);
    await p.setBool('card_gauges_row2',    config.gaugesRow2);
    await p.setBool('card_bar_chart',      config.barChart);
    await p.setBool('card_pie_chart',      config.pieChart);
  }
}

final dashboardConfigProvider =
    StateNotifierProvider<DashboardConfigNotifier, DashboardCardConfig>((ref) {
  final n = DashboardConfigNotifier();
  n.load();
  return n;
});

