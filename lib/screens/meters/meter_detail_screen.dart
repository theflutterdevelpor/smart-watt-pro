import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/charts/phase_line_chart.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/time_filter_bar.dart';

class MeterDetailScreen extends StatefulWidget {
  final String meterId;
  const MeterDetailScreen({super.key, required this.meterId});

  @override
  State<MeterDetailScreen> createState() => _MeterDetailScreenState();
}

class _MeterDetailScreenState extends State<MeterDetailScreen> {
  TimeFilter _timeFilter = TimeFilter.today;
  ParameterType _selectedParam = ParameterType.power;

  static const _mainParams = [
    ParameterType.energyConsumption,
    ParameterType.voltage,
    ParameterType.current,
    ParameterType.power,
    ParameterType.cost,
  ];

  static const _advancedParams = [
    ParameterType.powerFactor,
    ParameterType.frequency,
    ParameterType.peakDemand,
    ParameterType.activePower,
    ParameterType.reactivePower,
    ParameterType.costPerUnit,
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final meter = provider.getMeterById(widget.meterId);
    if (meter == null) return const Scaffold(body: Center(child: Text('Meter not found')));

    final isThreePhase = meter.type == MeterType.threePhase;
    final reading = meter.latestReading;
    final graphData = provider.getHistoricalData(_selectedParam, _timeFilter, meter.type);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meter.name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${isThreePhase ? "3-Phase" : "Single Phase"} • ${meter.role}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => context.go('/meters'),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: StatusChip(label: meter.status.label, color: meter.status.color),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sync info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      const Icon(Icons.sync, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('Last sync: ${DateFormat('HH:mm:ss').format(meter.lastSyncAt)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const Spacer(),
                      Text('ID: ${meter.meterId}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Time filter
                  TimeFilterBar(
                    selected: _timeFilter,
                    onChanged: (f) => setState(() => _timeFilter = f),
                  ),
                  const SizedBox(height: 20),

                  // Main parameters
                  SectionHeader(title: 'Main Parameters'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: _mainParams.map((p) =>
                        _paramCard(context, p, reading, isThreePhase)).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Advanced parameters
                  SectionHeader(title: 'Advanced Parameters'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: _advancedParams.map((p) =>
                        _paramCard(context, p, reading, isThreePhase)).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Graph preview
                  SectionHeader(
                    title: '${_selectedParam.info.name} Trend',
                    action: 'Full Screen',
                    onAction: () => context.go('/parameter/${_selectedParam.name}'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: PhaseLineChart(
                      data: graphData,
                      parameter: _selectedParam,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PhaseLegend(
                    showP1: true, showP2: true, showP3: true, showTotal: true,
                    isThreePhase: isThreePhase,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paramCard(BuildContext context, ParameterType param,
      MeterReading reading, bool isThreePhase) {
    final info = param.info;
    final values = reading.valuesFor(param);
    final isSelected = _selectedParam == param;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedParam = param);
        context.go('/parameter/${param.name}');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? info.color.withValues(alpha: 0.1)
              : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? info.color : AppColors.border,
              width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(info.icon, color: info.color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(info.name,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            Text(
              '${values.total.toStringAsFixed(values.total < 10 ? 2 : 1)} ${info.shortUnit}',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: info.color),
            ),
            if (isThreePhase)
              Text(
                'P1:${values.phase1.toStringAsFixed(1)} P2:${values.phase2.toStringAsFixed(1)} P3:${values.phase3.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
