import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common/status_chip.dart';

class ThresholdsScreen extends StatefulWidget {
  const ThresholdsScreen({super.key});

  @override
  State<ThresholdsScreen> createState() => _ThresholdsScreenState();
}

class _ThresholdsScreenState extends State<ThresholdsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final thresholds = provider.thresholdsForSelectedHome;
    final basic = thresholds.where((t) => [
      ParameterType.energyConsumption, ParameterType.cost,
      ParameterType.voltage, ParameterType.power,
    ].contains(t.parameter)).toList();
    final advanced = thresholds.where((t) => ![
      ParameterType.energyConsumption, ParameterType.cost,
      ParameterType.voltage, ParameterType.power,
    ].contains(t.parameter)).toList();

    final active = thresholds.where((t) => t.isActive && !t.isTriggered).length;
    final triggered = thresholds.where((t) => t.isTriggered).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thresholds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/thresholds/create'),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'Basic'), Tab(text: 'Advanced')],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: Column(
        children: [
          // Health summary
          Container(
            color: AppColors.cardWhite,
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              _healthBadge('Active', active, AppColors.normalGreen),
              const SizedBox(width: 10),
              _healthBadge('Triggered', triggered, AppColors.warningAmber),
              const SizedBox(width: 10),
              _healthBadge('Total', thresholds.length, AppColors.primary),
            ]),
          ),
          const Divider(height: 1),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _thresholdList(context, basic),
                _thresholdList(context, advanced),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Rule', style: TextStyle(color: Colors.white)),
        onPressed: () => context.go('/thresholds/create'),
      ),
    );
  }

  Widget _healthBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text('$count',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _thresholdList(BuildContext context, List<ThresholdRule> rules) {
    if (rules.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.tune, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          const Text('No thresholds configured',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/thresholds/create'),
            child: const Text('Create Threshold'),
          ),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rules.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ruleCard(context, rules[i]),
      ),
    );
  }

  Widget _ruleCard(BuildContext context, ThresholdRule rule) {
    final info = rule.parameter.info;
    final condLabel = _condLabel(rule);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: rule.isTriggered
                ? AppColors.warningAmber.withValues(alpha: 0.4)
                : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(info.icon, color: info.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(info.name, style: Theme.of(context).textTheme.titleSmall),
            Text(rule.phaseOrTotal,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          if (rule.isTriggered)
            StatusChip(label: 'Triggered', color: AppColors.warningAmber)
          else
            StatusChip(label: 'Active', color: AppColors.normalGreen),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Text(condLabel,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
            const SizedBox(width: 12),
            Text(rule.durationMinutes > 0 ? 'for ${rule.durationMinutes} min' : 'instantly',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const Spacer(),
            SeverityChip(label: rule.severity.label, color: rule.severity.color),
          ]),
        ),
      ]),
    );
  }

  String _condLabel(ThresholdRule rule) {
    final unit = rule.parameter.info.shortUnit;
    switch (rule.condition) {
      case ThresholdCondition.greaterThan:
        return '> ${rule.value} $unit';
      case ThresholdCondition.lessThan:
        return '< ${rule.value} $unit';
      case ThresholdCondition.between:
        return '${rule.value} – ${rule.value2} $unit';
      case ThresholdCondition.outsideRange:
        return '< ${rule.value} or > ${rule.value2} $unit';
    }
  }
}
