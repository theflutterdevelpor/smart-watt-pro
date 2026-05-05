import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/charts/phase_bar_chart.dart';
import '../../widgets/common/time_filter_bar.dart';

class ParameterComparisonScreen extends StatefulWidget {
  final String paramName;
  const ParameterComparisonScreen({super.key, required this.paramName});

  @override
  State<ParameterComparisonScreen> createState() => _ParameterComparisonScreenState();
}

class _ParameterComparisonScreenState extends State<ParameterComparisonScreen> {
  TimeFilter _tf = TimeFilter.today;

  ParameterType get _param => ParameterType.values.firstWhere(
      (p) => p.name == widget.paramName, orElse: () => ParameterType.power);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final meter = provider.metersForSelectedHome.isNotEmpty
        ? provider.metersForSelectedHome.first : null;
    final reading = meter?.latestReading;
    final vals = reading?.valuesFor(_param);
    final info = _param.info;
    final data = provider.getHistoricalData(
        _param, _tf, meter?.type ?? MeterType.threePhase);

    String? insight;
    if (vals != null) {
      final diff = vals.highest - vals.lowest;
      final pct = vals.average != 0 ? diff / vals.average * 100 : 0;
      if (pct > 15) {
        insight = 'Phase imbalance detected: ${pct.toStringAsFixed(1)}% difference between phases. '
            'Highest phase: ${['P1','P2','P3'][[vals.phase1, vals.phase2, vals.phase3].indexOf(vals.highest)]}';
      } else {
        insight = 'Phases are well balanced (${pct.toStringAsFixed(1)}% variance). No action needed.';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${info.name} — Phase Comparison'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/parameter/${widget.paramName}'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TimeFilterBar(selected: _tf, onChanged: (f) => setState(() => _tf = f)),
          const SizedBox(height: 20),

          // Current phase values
          if (vals != null) ...[
            Text('Current Values', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(children: [
              _phaseCard('Phase 1', vals.phase1, info.shortUnit, AppColors.phase1),
              const SizedBox(width: 10),
              _phaseCard('Phase 2', vals.phase2, info.shortUnit, AppColors.phase2),
              const SizedBox(width: 10),
              _phaseCard('Phase 3', vals.phase3, info.shortUnit, AppColors.phase3),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.phaseTotal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.phaseTotal.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('3Φ Total / Average',
                      style: TextStyle(fontSize: 12, color: AppColors.phaseTotal,
                          fontWeight: FontWeight.w600)),
                  Text('${vals.total.toStringAsFixed(vals.total < 10 ? 2 : 1)} ${info.shortUnit}',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: AppColors.phaseTotal)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Min: ${vals.lowest.toStringAsFixed(1)} ${info.shortUnit}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text('Max: ${vals.highest.toStringAsFixed(1)} ${info.shortUnit}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text('Avg: ${vals.average.toStringAsFixed(1)} ${info.shortUnit}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Comparison bar chart
          Text('Phase Comparison Chart',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Container(
            height: 240,
            padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: PhaseBarChart(data: data, parameter: _param),
          ),
          const SizedBox(height: 20),

          // Insight
          if (insight != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.insights, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Phase Balance Insight',
                        style: TextStyle(fontWeight: FontWeight.w700,
                            fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(insight,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary,
                            height: 1.4)),
                  ]),
                ),
              ]),
            ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_alert_outlined, size: 16),
              label: const Text('Set Phase Imbalance Alert'),
              onPressed: () => context.go('/thresholds/create'),
            ),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _phaseCard(String label, double value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 6),
          Text(value.toStringAsFixed(value < 10 ? 2 : 1),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(unit,
              style: TextStyle(
                  fontSize: 10, color: color.withValues(alpha: 0.7))),
        ]),
      ),
    );
  }
}
