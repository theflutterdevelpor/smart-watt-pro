import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class CostCalculatorScreen extends StatefulWidget {
  const CostCalculatorScreen({super.key});

  @override
  State<CostCalculatorScreen> createState() => _CostCalculatorScreenState();
}

class _CostCalculatorScreenState extends State<CostCalculatorScreen> {
  final _budgetCtrl = TextEditingController();
  bool _init = false;

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final bill = provider.billEstimate;

    if (!_init) {
      _budgetCtrl.text = bill.budget.toStringAsFixed(0);
      _init = true;
    }

    final budget = double.tryParse(_budgetCtrl.text) ?? bill.budget;
    final spent = bill.estimatedTotal;
    final remaining = budget - spent;
    final daysInCycle = bill.cycleEnd.difference(bill.cycleStart).inDays;
    final daysPassed = DateTime.now().difference(bill.cycleStart).inDays.clamp(1, daysInCycle);
    final daysLeft = (daysInCycle - daysPassed).clamp(0, daysInCycle);
    final dailyAvgCost = spent / daysPassed;
    final allowedDailySpend = remaining > 0 ? remaining / daysLeft.clamp(1, daysInCycle) : 0.0;
    final allowedDailyUnits = allowedDailySpend / bill.avgCostPerUnit.clamp(1, 999);
    final requiredReduction = dailyAvgCost - allowedDailySpend;
    final pctUsed = (spent / budget * 100).clamp(0, 999);
    final isOver = spent > budget;
    final projectedOver = bill.projectedBill > budget;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cost Calculator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/cost'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget input
            _card(context, children: [
              Text('Monthly Budget (PKR)',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              TextField(
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  prefixText: '₨ ',
                  prefixStyle: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                  hintText: '0',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const Divider(),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: _budgetChip(context, '5,000', 5000, budget)),
                const SizedBox(width: 8),
                Expanded(child: _budgetChip(context, '8,000', 8000, budget)),
                const SizedBox(width: 8),
                Expanded(child: _budgetChip(context, '12,000', 12000, budget)),
                const SizedBox(width: 8),
                Expanded(child: _budgetChip(context, '20,000', 20000, budget)),
              ]),
            ]),
            const SizedBox(height: 16),

            // Budget ring
            _card(context, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Budget Used', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text('${pctUsed.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.w800,
                            color: isOver ? AppColors.criticalRed : AppColors.primary)),
                    Text('of ₨${NumberFormat('#,##0').format(budget.toInt())}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ]),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: pctUsed / 100,
                        strokeWidth: 10,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(
                            isOver ? AppColors.criticalRed : AppColors.primary),
                        strokeCap: StrokeCap.round,
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          isOver ? 'OVER' : remaining >= 0
                              ? '₨${_compact(remaining)}' : '₨0',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: isOver ? AppColors.criticalRed : AppColors.primary),
                        ),
                        Text(isOver ? 'limit' : 'left',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textSecondary)),
                      ]),
                    ],
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 16),

            // Stats grid
            Row(children: [
              Expanded(child: _statCard(context,
                  '₨${NumberFormat('#,##0').format(spent.toInt())}',
                  'Spent so far', AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _statCard(context,
                  '₨${NumberFormat('#,##0').format(remaining.abs().toInt())}',
                  remaining >= 0 ? 'Remaining' : 'Over budget',
                  remaining >= 0 ? AppColors.normalGreen : AppColors.criticalRed)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard(context,
                  '₨${dailyAvgCost.toStringAsFixed(0)}/day',
                  'Current daily avg', AppColors.textSecondary)),
              const SizedBox(width: 12),
              Expanded(child: _statCard(context,
                  allowedDailySpend > 0
                      ? '₨${allowedDailySpend.toStringAsFixed(0)}/day'
                      : 'Budget exceeded',
                  'Allowed daily spend',
                  allowedDailySpend > 0 ? AppColors.normalGreen : AppColors.criticalRed)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard(context,
                  '${allowedDailyUnits.toStringAsFixed(1)} kWh',
                  'Allowed daily units',
                  AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _statCard(context,
                  '$daysLeft days',
                  'Days remaining in cycle', AppColors.textSecondary)),
            ]),
            const SizedBox(height: 16),

            // Insight banner
            if (projectedOver || requiredReduction > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.warningAmber.withValues(alpha: 0.3)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.lightbulb_outline,
                      color: AppColors.warningAmber, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Insight',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.warningAmber, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        projectedOver
                            ? 'Projected bill ₨${NumberFormat('#,##0').format(bill.projectedBill.toInt())} exceeds your budget by ₨${NumberFormat('#,##0').format((bill.projectedBill - budget).toInt())}. '
                                'Reduce daily usage by ${requiredReduction > 0 ? '₨${requiredReduction.toStringAsFixed(0)}/day' : 'any amount'} to stay within budget.'
                            : 'You are on track. Keep daily spending under ₨${allowedDailySpend.toStringAsFixed(0)} to stay within budget.',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary,
                            height: 1.4),
                      ),
                    ]),
                  ),
                ]),
              ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_alert_outlined, size: 16),
                label: const Text('Create Budget Alert'),
                onPressed: () => context.go('/thresholds/create'),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _statCard(BuildContext context, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _budgetChip(BuildContext context, String label, double val, double current) {
    final selected = (current - val).abs() < 1;
    return GestureDetector(
      onTap: () {
        _budgetCtrl.text = val.toStringAsFixed(0);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text('₨$label',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  String _compact(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}
