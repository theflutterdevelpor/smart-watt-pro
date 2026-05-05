import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

class PhaseLineChart extends StatefulWidget {
  final List<PhaseDataPoint> data;
  final ParameterType parameter;
  final bool showPhase1;
  final bool showPhase2;
  final bool showPhase3;
  final bool showTotal;
  final double? warningMin;
  final double? warningMax;

  const PhaseLineChart({
    super.key,
    required this.data,
    required this.parameter,
    this.showPhase1 = true,
    this.showPhase2 = true,
    this.showPhase3 = true,
    this.showTotal = true,
    this.warningMin,
    this.warningMax,
  });

  @override
  State<PhaseLineChart> createState() => _PhaseLineChartState();
}

class _PhaseLineChartState extends State<PhaseLineChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();
    final spots1 = <FlSpot>[];
    final spots2 = <FlSpot>[];
    final spots3 = <FlSpot>[];
    final spotsT = <FlSpot>[];

    for (int i = 0; i < widget.data.length; i++) {
      final d = widget.data[i];
      final x = i.toDouble();
      spots1.add(FlSpot(x, double.parse(d.phase1.toStringAsFixed(2))));
      spots2.add(FlSpot(x, double.parse(d.phase2.toStringAsFixed(2))));
      spots3.add(FlSpot(x, double.parse(d.phase3.toStringAsFixed(2))));
      spotsT.add(FlSpot(x, double.parse(d.total.toStringAsFixed(2))));
    }

    final allVals = [
      if (widget.showPhase1) ...spots1.map((s) => s.y),
      if (widget.showPhase2) ...spots2.map((s) => s.y),
      if (widget.showPhase3) ...spots3.map((s) => s.y),
      if (widget.showTotal) ...spotsT.map((s) => s.y),
    ];
    if (allVals.isEmpty) return const SizedBox.shrink();
    final minY = (allVals.reduce((a, b) => a < b ? a : b) * 0.95);
    final maxY = (allVals.reduce((a, b) => a > b ? a : b) * 1.05);

    final lines = <LineChartBarData>[
      if (widget.showPhase1)
        _line(spots1, AppColors.phase1),
      if (widget.showPhase2)
        _line(spots2, AppColors.phase2),
      if (widget.showPhase3)
        _line(spots3, AppColors.phase3),
      if (widget.showTotal)
        _line(spotsT, AppColors.phaseTotal, isDashed: true),
    ];

    return LineChart(
      LineChartData(
        lineBarsData: lines,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                _formatVal(v),
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
              interval: (widget.data.length / 5).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= widget.data.length) return const SizedBox.shrink();
                return Text(
                  _formatTime(widget.data[idx].time),
                  style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItems: (spots) => spots.map((s) {
              final colors = [AppColors.phase1, AppColors.phase2, AppColors.phase3, AppColors.phaseTotal];
              final labels = ['P1', 'P2', 'P3', 'Total'];
              return LineTooltipItem(
                '${labels[s.barIndex]}: ${_formatVal(s.y)} ${widget.parameter.info.shortUnit}',
                TextStyle(color: colors[s.barIndex], fontSize: 11, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
        extraLinesData: widget.warningMin != null || widget.warningMax != null
            ? ExtraLinesData(horizontalLines: [
                if (widget.warningMin != null)
                  HorizontalLine(
                    y: widget.warningMin!,
                    color: AppColors.warningAmber,
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                  ),
                if (widget.warningMax != null)
                  HorizontalLine(
                    y: widget.warningMax!,
                    color: AppColors.criticalRed,
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                  ),
              ])
            : const ExtraLinesData(),
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color, {bool isDashed = false}) {
    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: 2,
      isCurved: true,
      curveSmoothness: 0.3,
      dotData: const FlDotData(show: false),
      dashArray: isDashed ? [6, 4] : null,
      belowBarData: BarAreaData(
        show: !isDashed,
        color: color.withValues(alpha: 0.06),
      ),
    );
  }

  String _formatVal(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v < 10) return v.toStringAsFixed(2);
    return v.toStringAsFixed(1);
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

// ── Phase Legend ─────────────────────────────────────────────────────────────

class PhaseLegend extends StatefulWidget {
  final bool showP1;
  final bool showP2;
  final bool showP3;
  final bool showTotal;
  final bool isThreePhase;
  final ValueChanged<({bool p1, bool p2, bool p3, bool total})> onChanged;

  const PhaseLegend({
    super.key,
    required this.showP1,
    required this.showP2,
    required this.showP3,
    required this.showTotal,
    required this.isThreePhase,
    required this.onChanged,
  });

  @override
  State<PhaseLegend> createState() => _PhaseLegendState();
}

class _PhaseLegendState extends State<PhaseLegend> {
  late bool _p1, _p2, _p3, _total;

  @override
  void initState() {
    super.initState();
    _p1 = widget.showP1;
    _p2 = widget.showP2;
    _p3 = widget.showP3;
    _total = widget.showTotal;
  }

  void _toggle(String phase) {
    setState(() {
      if (phase == 'p1') _p1 = !_p1;
      if (phase == 'p2') _p2 = !_p2;
      if (phase == 'p3') _p3 = !_p3;
      if (phase == 'total') _total = !_total;
    });
    widget.onChanged((p1: _p1, p2: _p2, p3: _p3, total: _total));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (widget.isThreePhase) ...[
          _chip('P1', AppColors.phase1, _p1, () => _toggle('p1')),
          _chip('P2', AppColors.phase2, _p2, () => _toggle('p2')),
          _chip('P3', AppColors.phase3, _p3, () => _toggle('p3')),
        ],
        _chip(widget.isThreePhase ? '3Φ Total' : 'Total', AppColors.phaseTotal, _total,
            () => _toggle('total')),
      ],
    );
  }

  Widget _chip(String label, Color color, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : AppColors.neutral,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? color : AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? color : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
