import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

class PhaseBarChart extends StatelessWidget {
  final List<PhaseDataPoint> data;
  final ParameterType parameter;

  const PhaseBarChart({super.key, required this.data, required this.parameter});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data
        .map((d) => d.total)
        .reduce((a, b) => a > b ? a : b) * 1.1;

    return BarChart(
      BarChartData(
        maxY: maxVal,
        barGroups: data.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: d.total,
                width: data.length > 15 ? 6 : 12,
                borderRadius: BorderRadius.circular(4),
                rodStackItems: [
                  BarChartRodStackItem(0, d.phase1, AppColors.phase1),
                  BarChartRodStackItem(d.phase1, d.phase1 + d.phase2, AppColors.phase2),
                  BarChartRodStackItem(
                      d.phase1 + d.phase2, d.total, AppColors.phase3),
                ],
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (data.length / 5).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                final t = data[idx].time;
                return Text(
                  '${t.day}/${t.month}',
                  style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItem: (group, _, rod,  state) {
              final d = data[group.x];
              return BarTooltipItem(
                'P1: ${d.phase1.toStringAsFixed(1)}\nP2: ${d.phase2.toStringAsFixed(1)}\nP3: ${d.phase3.toStringAsFixed(1)}\nTotal: ${d.total.toStringAsFixed(1)} ${parameter.info.shortUnit}',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            },
          ),
        ),
      ),
    );
  }
}
