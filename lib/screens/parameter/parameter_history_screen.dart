import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/charts/phase_line_chart.dart';
import '../../widgets/common/time_filter_bar.dart';

class ParameterHistoryScreen extends StatefulWidget {
  final String paramName;
  const ParameterHistoryScreen({super.key, required this.paramName});

  @override
  State<ParameterHistoryScreen> createState() => _ParameterHistoryScreenState();
}

class _ParameterHistoryScreenState extends State<ParameterHistoryScreen> {
  TimeFilter _tf = TimeFilter.sevenDays;
  bool _showP1 = true, _showP2 = true, _showP3 = true, _showTotal = true;

  ParameterType get _param => ParameterType.values.firstWhere(
      (p) => p.name == widget.paramName, orElse: () => ParameterType.power);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final meter = provider.metersForSelectedHome.isNotEmpty
        ? provider.metersForSelectedHome.first : null;
    final isThreePhase = meter?.type == MeterType.threePhase;
    final info = _param.info;
    final data = provider.getHistoricalData(
        _param, _tf, meter?.type ?? MeterType.threePhase);

    double? minV, maxV, avgV;
    int alertCount = 0;
    if (data.isNotEmpty) {
      final totals = data.map((d) => d.total).toList();
      minV = totals.reduce((a, b) => a < b ? a : b);
      maxV = totals.reduce((a, b) => a > b ? a : b);
      avgV = totals.reduce((a, b) => a + b) / totals.length;
      alertCount = provider.alertsForSelectedHome
          .where((a) => a.parameter == _param).length;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${info.name} History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/parameter/${widget.paramName}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Time filter
          TimeFilterBar(
            selected: _tf,
            onChanged: (f) => setState(() => _tf = f),
            includeLive: false,
          ),
          const SizedBox(height: 20),

          // Stats row
          if (minV != null && maxV != null && avgV != null) ...[
            Row(children: [
              _statCard('Min', minV, info.shortUnit, AppColors.normalGreen),
              const SizedBox(width: 10),
              _statCard('Max', maxV, info.shortUnit, AppColors.criticalRed),
              const SizedBox(width: 10),
              _statCard('Avg', avgV, info.shortUnit, AppColors.primary),
              const SizedBox(width: 10),
              _alertCard(alertCount),
            ]),
            const SizedBox(height: 20),
          ],

          // Chart
          Text('Historical Trend', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Container(
            height: 260,
            padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: PhaseLineChart(
              data: data,
              parameter: _param,
              showPhase1: _showP1,
              showPhase2: _showP2 && isThreePhase,
              showPhase3: _showP3 && isThreePhase,
              showTotal: _showTotal,
              warningMin: _safeMin(_param),
              warningMax: _safeMax(_param),
            ),
          ),
          const SizedBox(height: 10),
          PhaseLegend(
            showP1: _showP1, showP2: _showP2, showP3: _showP3, showTotal: _showTotal,
            isThreePhase: isThreePhase,
            onChanged: (v) => setState(() {
              _showP1 = v.p1; _showP2 = v.p2; _showP3 = v.p3; _showTotal = v.total;
            }),
          ),
          const SizedBox(height: 20),

          // Event list
          Text('Alert Events', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          ...provider.alertsForSelectedHome
              .where((a) => a.parameter == _param)
              .take(10)
              .map((a) => _eventTile(context, a)),

          if (provider.alertsForSelectedHome
              .where((a) => a.parameter == _param)
              .isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text('No alert events for this parameter',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ),

          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_alert_outlined, size: 16),
                label: const Text('Set Threshold'),
                onPressed: () => context.go('/thresholds/create'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.compare_arrows, size: 16),
                label: const Text('Compare Phases'),
                onPressed: () => context.go('/parameter/${widget.paramName}/compare'),
              ),
            ),
          ]),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _statCard(String label, double val, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(val.toStringAsFixed(val < 10 ? 2 : 1),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(unit, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _alertCard(int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningAmber.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text('$count',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppColors.warningAmber)),
          const Text('events',
              style: TextStyle(fontSize: 9, color: AppColors.warningAmber)),
          const Text('Alerts',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _eventTile(BuildContext context, AlertModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: a.severity.color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(_paramIcon(a.parameter), color: a.severity.color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.type,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(
              '${a.phaseOrTotal} • ${a.actualValue.toStringAsFixed(1)} ${a.parameter.info.shortUnit} (limit ${a.thresholdValue.toStringAsFixed(1)})',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ]),
        ),
        Text(
          DateFormat('dd/MM HH:mm').format(a.createdAt),
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ]),
    );
  }

  IconData _paramIcon(ParameterType p) {
    switch (p) {
      case ParameterType.voltage: return Icons.electric_bolt;
      case ParameterType.current: return Icons.electrical_services;
      case ParameterType.power: return Icons.power;
      default: return Icons.warning_amber_rounded;
    }
  }

  double? _safeMin(ParameterType p) {
    switch (p) {
      case ParameterType.voltage: return 200.0;
      case ParameterType.frequency: return 49.0;
      case ParameterType.powerFactor: return 0.85;
      default: return null;
    }
  }

  double? _safeMax(ParameterType p) {
    switch (p) {
      case ParameterType.voltage: return 240.0;
      case ParameterType.frequency: return 51.0;
      default: return null;
    }
  }
}
