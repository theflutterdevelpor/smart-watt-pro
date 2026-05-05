import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

class CreateThresholdScreen extends StatefulWidget {
  const CreateThresholdScreen({super.key});

  @override
  State<CreateThresholdScreen> createState() => _CreateThresholdScreenState();
}

class _CreateThresholdScreenState extends State<CreateThresholdScreen> {
  ParameterType _param = ParameterType.voltage;
  String _phase = 'Any Phase';
  ThresholdCondition _condition = ThresholdCondition.outsideRange;
  AlertSeverity _severity = AlertSeverity.warning;
  final _val1Ctrl = TextEditingController(text: '200');
  final _val2Ctrl = TextEditingController(text: '240');
  int _duration = 5;
  bool _notify = true;

  static const _phases = ['Phase 1', 'Phase 2', 'Phase 3', 'Any Phase', 'Total'];

  @override
  void dispose() {
    _val1Ctrl.dispose();
    _val2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needsTwo = _condition == ThresholdCondition.between ||
        _condition == ThresholdCondition.outsideRange;
    final info = _param.info;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Threshold'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/thresholds'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, 'Parameter'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ParameterType.values.map((p) {
                final selected = p == _param;
                return GestureDetector(
                  onTap: () => setState(() => _param = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? p.info.color.withValues(alpha: 0.1) : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? p.info.color : AppColors.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(p.info.icon, size: 13,
                          color: selected ? p.info.color : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(p.info.name,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: selected ? p.info.color : AppColors.textSecondary)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _sectionTitle(context, 'Phase / Scope'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _phases.map((ph) {
                final selected = ph == _phase;
                return GestureDetector(
                  onTap: () => setState(() => _phase = ph),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(ph,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: selected ? AppColors.primary : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _sectionTitle(context, 'Condition'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ThresholdCondition.values.map((c) {
                final selected = c == _condition;
                return GestureDetector(
                  onTap: () => setState(() => _condition = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(_condLabel(c),
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: selected ? AppColors.primary : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            _sectionTitle(context, 'Value (${info.shortUnit})'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _val1Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: needsTwo ? 'Min Value' : 'Threshold Value',
                    suffixText: info.shortUnit,
                  ),
                ),
              ),
              if (needsTwo) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _val2Ctrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Value',
                      suffixText: info.shortUnit,
                    ),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 20),

            _sectionTitle(context, 'Duration (minutes)'),
            const SizedBox(height: 10),
            Row(children: [
              for (final d in [0, 1, 5, 10, 15, 30])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _duration = d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _duration == d ? AppColors.primary : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _duration == d ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(d == 0 ? 'Instant' : '${d}m',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: _duration == d ? Colors.white : AppColors.textSecondary)),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 20),

            _sectionTitle(context, 'Severity'),
            const SizedBox(height: 10),
            Row(children: AlertSeverity.values.map((s) {
              final selected = s == _severity;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: s != AlertSeverity.critical ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _severity = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? s.color.withValues(alpha: 0.1) : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selected ? s.color : AppColors.border),
                      ),
                      child: Column(children: [
                        Icon(Icons.circle, color: s.color, size: 10),
                        const SizedBox(height: 4),
                        Text(s.label,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: s.color)),
                      ]),
                    ),
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 20),

            SwitchListTile(
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
              title: const Text('Push Notification'),
              subtitle: const Text('Alert via push notification when triggered'),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/thresholds'),
                child: const Text('Save Threshold'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleSmall);
  }

  String _condLabel(ThresholdCondition c) {
    switch (c) {
      case ThresholdCondition.greaterThan: return 'Greater than';
      case ThresholdCondition.lessThan: return 'Less than';
      case ThresholdCondition.between: return 'Between (within range)';
      case ThresholdCondition.outsideRange: return 'Outside safe range';
    }
  }
}
