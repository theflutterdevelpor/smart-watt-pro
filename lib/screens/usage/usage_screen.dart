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

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  TimeFilter _timeFilter = TimeFilter.sevenDays;
  ParameterType _selectedParam = ParameterType.energyConsumption;
  bool _showP1 = true, _showP2 = true, _showP3 = true, _showTotal = true;
  String? _selectedMeterId;

  static const _allParams = ParameterType.values;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final meters = provider.metersForSelectedHome;
    final meterForData = _selectedMeterId != null
        ? provider.getMeterById(_selectedMeterId!)
        : meters.isNotEmpty ? meters.first : null;

    final isThreePhase = meterForData?.type == MeterType.threePhase;
    final data = provider.getHistoricalData(
        _selectedParam, _timeFilter, meterForData?.type ?? MeterType.threePhase);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Usage & Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scope filters
            SectionHeader(title: 'Scope'),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _scopeChip(context, null, 'All Meters'),
                  const SizedBox(width: 8),
                  ...meters.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _scopeChip(context, m.id, m.name),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Parameter selector
            SectionHeader(title: 'Parameter'),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _allParams.length,
                separatorBuilder: (context, state) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = _allParams[i];
                  final selected = p == _selectedParam;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedParam = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? p.info.color : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected ? p.info.color : AppColors.border),
                      ),
                      child: Row(children: [
                        Icon(p.info.icon,
                            size: 13,
                            color: selected ? Colors.white : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(p.info.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.textSecondary,
                            )),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Time filter
            TimeFilterBar(
              selected: _timeFilter,
              onChanged: (f) => setState(() => _timeFilter = f),
              includeLive: false,
            ),
            const SizedBox(height: 20),

            // Main chart
            SectionHeader(
              title: '${_selectedParam.info.name} (${_selectedParam.info.shortUnit})',
              action: 'Full Detail',
              onAction: () => context.go('/parameter/${_selectedParam.name}'),
            ),
            const SizedBox(height: 12),
            Container(
              height: 260,
              padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: _selectedParam == ParameterType.energyConsumption
                  ? PhaseBarChart(data: data, parameter: _selectedParam)
                  : PhaseLineChart(
                      data: data,
                      parameter: _selectedParam,
                      showPhase1: _showP1,
                      showPhase2: _showP2 && isThreePhase,
                      showPhase3: _showP3 && isThreePhase,
                      showTotal: _showTotal,
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

            // Comparison card
            _comparisonCard(context, data),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _scopeChip(BuildContext context, String? id, String label) {
    final selected = _selectedMeterId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMeterId = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }

  Widget _comparisonCard(BuildContext context, List<PhaseDataPoint> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    final totals = data.map((d) => d.total).toList();
    final current = totals.last;
    final prev = totals.length > 1 ? totals[totals.length ~/ 2] : totals.first;
    final diff = current - prev;
    final pct = prev != 0 ? (diff / prev * 100).abs() : 0.0;
    final isUp = diff > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Period Comparison', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _compItem('Current', current, _selectedParam.info.shortUnit, AppColors.primary)),
            Container(width: 1, height: 40, color: AppColors.border),
            Expanded(child: _compItem('Previous', prev, _selectedParam.info.shortUnit, AppColors.textSecondary)),
            Container(width: 1, height: 40, color: AppColors.border),
            Expanded(
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(isUp ? Icons.trending_up : Icons.trending_down,
                      color: isUp ? AppColors.criticalRed : AppColors.normalGreen, size: 18),
                  const SizedBox(width: 4),
                  Text('${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: isUp ? AppColors.criticalRed : AppColors.normalGreen)),
                ]),
                Text('vs previous', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _compItem(String label, double value, String unit, Color color) {
    return Column(children: [
      Text('${value.toStringAsFixed(1)} $unit',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]);
  }
}
