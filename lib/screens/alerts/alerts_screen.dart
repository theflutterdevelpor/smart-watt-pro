import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common/status_chip.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    var alerts = provider.alertsForSelectedHome;
    if (_filter != null) alerts = alerts.where((a) => a.status == _filter).toList();

    final criticalCount = alerts.where((a) => a.severity == AlertSeverity.critical).length;
    final warningCount = alerts.where((a) => a.severity == AlertSeverity.warning).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Alerts')),
      body: Column(
        children: [
          // Summary bar
          Container(
            color: AppColors.cardWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              _summaryBadge(context, 'Critical', criticalCount, AppColors.criticalRed),
              const SizedBox(width: 12),
              _summaryBadge(context, 'Warning', warningCount, AppColors.warningAmber),
              const SizedBox(width: 12),
              _summaryBadge(context, 'Total', alerts.length, AppColors.primary),
            ]),
          ),
          const Divider(height: 1),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              _chip(null, 'All'),
              const SizedBox(width: 8),
              _chip(AlertStatus.active, 'Active'),
              const SizedBox(width: 8),
              _chip(AlertStatus.acknowledged, 'Acknowledged'),
              const SizedBox(width: 8),
              _chip(AlertStatus.resolved, 'Resolved'),
            ]),
          ),

          Expanded(
            child: alerts.isEmpty
                ? _emptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: alerts.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _alertCard(context, alerts[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBadge(BuildContext context, String label, int count, Color color) {
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

  Widget _chip(AlertStatus? status, String label) {
    final selected = _filter == status;
    return GestureDetector(
      onTap: () => setState(() => _filter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }

  Widget _alertCard(BuildContext context, AlertModel alert) {
    return GestureDetector(
      onTap: () => context.go('/alerts/${alert.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: alert.severity.color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: alert.severity.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_alertIcon(alert.parameter),
                  color: alert.severity.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(alert.type, style: Theme.of(context).textTheme.titleSmall),
              Text(
                '${alert.parameter.info.name} • ${alert.phaseOrTotal}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ])),
            SeverityChip(label: alert.severity.label, color: alert.severity.color),
          ]),
          const SizedBox(height: 10),
          Text(alert.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(children: [
            Text(
              'Value: ${alert.actualValue.toStringAsFixed(1)} ${alert.parameter.info.shortUnit}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text('•', style: const TextStyle(color: AppColors.textTertiary)),
            const SizedBox(width: 8),
            Text(
              'Limit: ${alert.thresholdValue.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              _timeAgo(alert.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ]),
          if (alert.status == AlertStatus.active) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Acknowledge', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Resolve', style: TextStyle(fontSize: 12)),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.notifications_off_outlined,
            size: 64, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        Text('No alerts', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('All clear — no active alerts for this home',
            style: TextStyle(color: AppColors.textSecondary)),
      ]),
    );
  }

  IconData _alertIcon(ParameterType param) {
    switch (param) {
      case ParameterType.voltage: return Icons.electric_bolt;
      case ParameterType.current: return Icons.electrical_services;
      case ParameterType.power: return Icons.power;
      case ParameterType.energyConsumption: return Icons.bolt;
      case ParameterType.cost: return Icons.payments;
      default: return Icons.warning_amber_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
