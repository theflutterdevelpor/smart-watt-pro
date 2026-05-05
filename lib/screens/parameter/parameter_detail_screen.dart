import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/charts/phase_bar_chart.dart';
import '../../widgets/charts/phase_line_chart.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/time_filter_bar.dart';

class ParameterDetailScreen extends StatefulWidget {
  final String paramName;

  const ParameterDetailScreen({super.key, required this.paramName});

  @override
  State<ParameterDetailScreen> createState() => _ParameterDetailScreenState();
}

class _ParameterDetailScreenState extends State<ParameterDetailScreen> {
  TimeFilter _timeFilter = TimeFilter.today;
  bool _showP1 = true, _showP2 = true, _showP3 = true, _showTotal = true;

  ParameterType get _param {
    return ParameterType.values.firstWhere(
      (p) => p.name == widget.paramName,
      orElse: () => ParameterType.power,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final param = _param;
    final info = param.info;
    final meter = provider.metersForSelectedHome.isNotEmpty
        ? provider.metersForSelectedHome.first
        : null;
    final isThreePhase = meter?.type == MeterType.threePhase;
    final reading = meter?.latestReading;
    final data = provider.getHistoricalData(param, _timeFilter, meter?.type ?? MeterType.threePhase);

    final vals = reading?.valuesFor(param);

    // Compute summary from historical data
    double? minVal, maxVal, avgVal, totalVal;
    if (data.isNotEmpty) {
      final totals = data.map((d) => d.total).toList();
      minVal = totals.reduce((a, b) => a < b ? a : b);
      maxVal = totals.reduce((a, b) => a > b ? a : b);
      avgVal = totals.reduce((a, b) => a + b) / totals.length;
      totalVal = totals.reduce((a, b) => a + b);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(info.icon, color: info.color, size: 18),
                  const SizedBox(width: 6),
                  Text(info.name),
                ]),
                Text(
                  '${provider.selectedHome.name} › ${meter?.name ?? ""}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.compare_arrows),
                tooltip: 'Compare Phases',
                onPressed: () => context.go('/parameter/${param.name}/compare'),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Set Threshold',
                onPressed: () => context.go('/thresholds/create'),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time filter
                  TimeFilterBar(
                    selected: _timeFilter,
                    onChanged: (f) => setState(() => _timeFilter = f),
                  ),
                  const SizedBox(height: 20),

                  // Phase value cards
                  if (vals != null) ...[
                    _phaseValueRow(context, vals, info, isThreePhase),
                    const SizedBox(height: 20),
                  ],

                  // Graph
                  SectionHeader(title: '${info.name} Trend (${info.shortUnit})'),
                  const SizedBox(height: 12),
                  Container(
                    height: 240,
                    padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: param == ParameterType.energyConsumption
                        ? PhaseBarChart(data: data, parameter: param)
                        : PhaseLineChart(
                            data: data,
                            parameter: param,
                            showPhase1: _showP1,
                            showPhase2: _showP2 && isThreePhase,
                            showPhase3: _showP3 && isThreePhase,
                            showTotal: _showTotal,
                            warningMin: _warningMin(param),
                            warningMax: _warningMax(param),
                          ),
                  ),
                  const SizedBox(height: 10),
                  PhaseLegend(
                    showP1: _showP1,
                    showP2: _showP2,
                    showP3: _showP3,
                    showTotal: _showTotal,
                    isThreePhase: isThreePhase,
                    onChanged: (v) => setState(() {
                      _showP1 = v.p1;
                      _showP2 = v.p2;
                      _showP3 = v.p3;
                      _showTotal = v.total;
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Summary stats
                  if (minVal != null) ...[
                    SectionHeader(title: 'Summary'),
                    const SizedBox(height: 12),
                    _summaryGrid(context, param, info, minVal, maxVal!, avgVal!, totalVal!),
                    const SizedBox(height: 20),
                  ],

                  // Threshold note
                  _thresholdBanner(context, param),
                  const SizedBox(height: 20),

                  // Actions
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_alert, size: 16),
                        label: const Text('Set Threshold'),
                        onPressed: () => context.go('/thresholds/create'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('View History'),
                        onPressed: () => context.go('/parameter/${param.name}/history'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _phaseValueRow(BuildContext context, PhaseValues vals,
      ParameterInfo info, bool isThreePhase) {
    final cards = isThreePhase
        ? [
            ('Phase 1', vals.phase1, AppColors.phase1),
            ('Phase 2', vals.phase2, AppColors.phase2),
            ('Phase 3', vals.phase3, AppColors.phase3),
            ('Total / 3Φ', vals.total, AppColors.phaseTotal),
          ]
        : [
            ('Total', vals.total, AppColors.phase1),
          ];

    return GridView.count(
      crossAxisCount: isThreePhase ? 2 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: isThreePhase ? 2.0 : 4.0,
      children: cards.map((c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: c.$3.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.$3.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(c.$1,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: c.$3)),
              Text(
                '${c.$2.toStringAsFixed(c.$2 < 10 ? 2 : 1)} ${info.shortUnit}',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: c.$3),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _summaryGrid(BuildContext context, ParameterType param, ParameterInfo info,
      double min, double max, double avg, double total) {
    final showTotal = param == ParameterType.energyConsumption ||
        param == ParameterType.cost ||
        param == ParameterType.power ||
        param == ParameterType.activePower ||
        param == ParameterType.reactivePower;

    final items = [
      ('Min', min, AppColors.normalGreen),
      ('Max', max, AppColors.criticalRed),
      ('Average', avg, AppColors.primary),
      if (showTotal) ('Total', total, AppColors.phaseTotal),
    ];

    return GridView.count(
      crossAxisCount: items.length == 4 ? 4 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.$2.toStringAsFixed(item.$2 < 10 ? 2 : 1),
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: item.$3),
              ),
              const SizedBox(height: 2),
              Text(info.shortUnit,
                  style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
              Text(item.$1,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _thresholdBanner(BuildContext context, ParameterType param) {
    final provider = context.watch<AppProvider>();
    final triggered = provider.allThresholds
        .where((t) => t.parameter == param && t.isTriggered)
        .toList();
    if (triggered.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${triggered.length} threshold${triggered.length > 1 ? 's' : ''} triggered for ${param.info.name}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.warningAmber),
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/alerts'),
          child: const Text('View',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.warningAmber)),
        ),
      ]),
    );
  }

  double? _warningMin(ParameterType param) {
    switch (param) {
      case ParameterType.voltage: return 200.0;
      case ParameterType.frequency: return 49.0;
      case ParameterType.powerFactor: return 0.85;
      default: return null;
    }
  }

  double? _warningMax(ParameterType param) {
    switch (param) {
      case ParameterType.voltage: return 240.0;
      case ParameterType.frequency: return 51.0;
      default: return null;
    }
  }
}
