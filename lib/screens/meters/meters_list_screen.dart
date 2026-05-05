import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/charts/mini_sparkline.dart';
import '../../widgets/common/status_chip.dart';

class MetersListScreen extends StatefulWidget {
  const MetersListScreen({super.key});

  @override
  State<MetersListScreen> createState() => _MetersListScreenState();
}

class _MetersListScreenState extends State<MetersListScreen> {
  MeterStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    var meters = provider.metersForSelectedHome;
    if (_filter != null) meters = meters.where((m) => m.status == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Meters — ${provider.selectedHome.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/add-meter'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _filterChip(context, null, 'All'),
                const SizedBox(width: 8),
                _filterChip(context, MeterStatus.online, 'Online'),
                const SizedBox(width: 8),
                _filterChip(context, MeterStatus.warning, 'Warning'),
                const SizedBox(width: 8),
                _filterChip(context, MeterStatus.offline, 'Offline'),
              ],
            ),
          ),
          Expanded(
            child: meters.isEmpty
                ? _emptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: meters.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _meterCard(context, meters[i], provider),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, MeterStatus? status, String label) {
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _meterCard(BuildContext context, MeterModel meter, AppProvider provider) {
    final sparkData = provider
        .getHistoricalData(ParameterType.power, TimeFilter.live, meter.type)
        .map((d) => d.total)
        .toList();

    return GestureDetector(
      onTap: () => context.go('/meters/${meter.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: meter.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.electric_meter_outlined,
                      color: meter.status.color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(meter.name,
                              style: Theme.of(context).textTheme.titleSmall),
                        ),
                        StatusChip(label: meter.status.label, color: meter.status.color),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        '${meter.meterId} • ${meter.type == MeterType.threePhase ? "3-Phase" : "1-Phase"}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat('Power', '${meter.latestReading.power.total.toStringAsFixed(2)} kW'),
                _stat('Energy', '${meter.latestReading.energyKwh.total.toStringAsFixed(1)} kWh'),
                _stat('Voltage', '${meter.latestReading.voltage.total.toStringAsFixed(0)} V'),
                _stat('Current', '${meter.latestReading.current.total.toStringAsFixed(1)} A'),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: MiniSparkline(values: sparkData, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.electric_meter_outlined,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('No meters found', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Add a smart energy meter to start monitoring',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Meter'),
            onPressed: () => context.go('/add-meter'),
          ),
        ],
      ),
    );
  }
}
