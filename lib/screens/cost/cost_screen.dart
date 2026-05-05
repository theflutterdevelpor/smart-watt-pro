import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../data/models/models.dart';
import '../../widgets/charts/phase_line_chart.dart';

class CostScreen extends StatelessWidget {
  const CostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final bill = provider.billEstimate;
    final tariff = provider.activeTariff;
    final costData = provider.getHistoricalData(
        ParameterType.cost, TimeFilter.billingCycle, MeterType.threePhase);

    final pct = (bill.estimatedTotal / bill.budget).clamp(0.0, 1.2);
    final isOver = bill.projectedBill > bill.budget;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cost & Bill Estimate'),
        actions: [
          TextButton(
            onPressed: () => context.go('/tariff'),
            child: const Text('Tariff Settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D5AFF), Color(0xFF4D7FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Bill',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tariff.provider} • ${tariff.tariffType.name.toUpperCase()}',
                          style: const TextStyle(color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₨${NumberFormat('#,##0').format(bill.estimatedTotal.toInt())}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${bill.totalUnits.toStringAsFixed(1)} units • Slab ${bill.currentSlab} (₨${bill.currentSlabRate}/unit)',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _billStat('Projected', '₨${NumberFormat('#,##0').format(bill.projectedBill.toInt())}',
                        isOver ? AppColors.criticalRed : AppColors.normalGreen)),
                    Expanded(child: _billStat('Budget', '₨${NumberFormat('#,##0').format(bill.budget.toInt())}',
                        Colors.white70)),
                    Expanded(child: _billStat('Avg Rate', '₨${bill.avgCostPerUnit.toStringAsFixed(2)}/u',
                        Colors.white70)),
                  ]),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0, 1),
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(
                          isOver ? AppColors.criticalRed : AppColors.normalGreen),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${(pct * 100).toStringAsFixed(0)}% of budget used',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      if (isOver)
                        const Text('OVER BUDGET',
                            style: TextStyle(color: AppColors.criticalRed,
                                fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cost trend chart
            Text('Cost Trend (Billing Cycle)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: PhaseLineChart(data: costData, parameter: ParameterType.cost),
            ),
            const SizedBox(height: 20),

            // Bill summary
            Text('Bill Summary', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _billBreakdown(context, bill),
            const SizedBox(height: 20),

            // Slab progress
            Text('Slab Progress', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _slabProgress(context, tariff, bill),
            const SizedBox(height: 20),

            // Actions
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Detailed Bill'),
                  onPressed: () => context.go('/bill-breakdown'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calculate_outlined, size: 16),
                  label: const Text('Calculator'),
                  onPressed: () => context.go('/cost-calculator'),
                ),
              ),
            ]),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _billStat(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ]);
  }

  Widget _billBreakdown(BuildContext context, bill) {
    final rows = [
      ('Energy Charges', bill.energyCharges),
      ('Fixed Charges', bill.fixedCharges),
      ('FPA', bill.fpaCharges),
      ('QTA', bill.qtaCharges),
      ('FC Surcharge', bill.fcSurcharge),
      ('Taxes (GST + others)', bill.taxes),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ...rows.asMap().entries.map((e) {
            final row = e.value;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.$1,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text('₨${NumberFormat('#,##0.00').format(row.$2)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (e.key < rows.length - 1) const Divider(height: 1),
            ]);
          }),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Estimated',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text('₨${NumberFormat('#,##0').format(bill.estimatedTotal.toInt())}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slabProgress(BuildContext context, TariffVersion tariff, bill) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: tariff.slabs.map((slab) {
          final isCurrentSlab = slab.fromUnits <= bill.totalUnits &&
              bill.totalUnits <= slab.toUnits;
          final unitsFilled = isCurrentSlab
              ? bill.totalUnits - slab.fromUnits
              : bill.totalUnits > slab.toUnits
                  ? (slab.toUnits - slab.fromUnits).toDouble()
                  : 0.0;
          final slabSize = slab.toUnits == 99999
              ? 100.0
              : (slab.toUnits - slab.fromUnits).toDouble();
          final progress = (unitsFilled / slabSize).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(slab.label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrentSlab ? FontWeight.w700 : FontWeight.w400,
                            color: isCurrentSlab
                                ? AppColors.primary
                                : AppColors.textSecondary)),
                    if (isCurrentSlab) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Current',
                            style: TextStyle(
                                fontSize: 9, color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  Text('₨${slab.ratePerUnit}/unit',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrentSlab ? FontWeight.w700 : FontWeight.w400,
                          color: isCurrentSlab ? AppColors.primary : AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(
                      isCurrentSlab ? AppColors.primary : AppColors.normalGreen),
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}
