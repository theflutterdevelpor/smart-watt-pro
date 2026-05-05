import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/charts/phase_line_chart.dart';
import '../../widgets/common/status_chip.dart';

class AlertDetailScreen extends StatelessWidget {
  final String alertId;
  const AlertDetailScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final alert = provider.allAlerts.firstWhere(
      (a) => a.id == alertId,
      orElse: () => provider.allAlerts.first,
    );
    final meter = provider.getMeterById(alert.meterId);
    final chartData = provider.getHistoricalData(
        alert.parameter, TimeFilter.today, meter?.type ?? MeterType.threePhase);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(alert.type),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/alerts'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SeverityChip(label: alert.severity.label, color: alert.severity.color),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: alert.severity.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: alert.severity.color.withValues(alpha: 0.25)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.warning_amber_rounded, color: alert.severity.color, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(alert.description,
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                ]),
                const SizedBox(height: 16),
                _infoRow('Parameter', alert.parameter.info.name),
                _infoRow('Phase / Scope', alert.phaseOrTotal),
                _infoRow('Actual Value',
                    '${alert.actualValue.toStringAsFixed(2)} ${alert.parameter.info.shortUnit}'),
                _infoRow('Threshold',
                    '${alert.thresholdValue.toStringAsFixed(2)} ${alert.parameter.info.shortUnit}'),
                _infoRow('Triggered', DateFormat('dd MMM yyyy HH:mm').format(alert.createdAt)),
                _infoRow('Status', alert.status.name.toUpperCase()),
              ]),
            ),
            const SizedBox(height: 20),

            // Event chart
            Text('Event Graph', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: PhaseLineChart(
                data: chartData,
                parameter: alert.parameter,
                warningMax: alert.thresholdValue,
              ),
            ),
            const SizedBox(height: 20),

            // Event history
            Text('Event History', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _eventTimeline(context, alert),
            const SizedBox(height: 20),

            // Actions
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Acknowledge'),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.volume_off_outlined, size: 16),
                  label: const Text('Mute'),
                  onPressed: () {},
                ),
              ),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.task_alt, size: 16),
                label: const Text('Mark Resolved'),
                onPressed: () => context.go('/alerts'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Edit Threshold'),
                onPressed: () => context.go('/thresholds/create'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _eventTimeline(BuildContext context, AlertModel alert) {
    final events = [
      (alert.createdAt, 'Alert triggered', AppColors.criticalRed),
      if (alert.acknowledgedAt != null)
        (alert.acknowledgedAt!, 'Acknowledged', AppColors.warningAmber),
      if (alert.resolvedAt != null)
        (alert.resolvedAt!, 'Resolved', AppColors.normalGreen),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: events.asMap().entries.map((e) {
          final isLast = e.key == events.length - 1;
          final ev = e.value;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: ev.$3, shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 32, color: AppColors.border),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ev.$2,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(DateFormat('HH:mm dd/MM').format(ev.$1),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
