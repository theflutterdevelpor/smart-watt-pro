import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class BillBreakdownScreen extends StatelessWidget {
  const BillBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bill = context.watch<AppProvider>().billEstimate;
    final tariff = context.watch<AppProvider>().activeTariff;
    final fmt = NumberFormat('#,##0.00');
    final fmt0 = NumberFormat('#,##0');

    final utilitySubtotal = bill.energyCharges + bill.fixedCharges +
        bill.fpaCharges + bill.qtaCharges + bill.fcSurcharge;
    final govSubtotal = bill.taxes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detailed Bill Breakdown'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/cost'),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.share_outlined, size: 16),
            label: const Text('Export'),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1D3461)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Estimated Bill',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tariff.provider,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 6),
              Text('₨${fmt0.format(bill.estimatedTotal.toInt())}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 36,
                      fontWeight: FontWeight.w800, letterSpacing: -1)),
              const SizedBox(height: 4),
              Text(
                '${bill.totalUnits.toStringAsFixed(1)} units • '
                'Slab ${bill.currentSlab} @ ₨${bill.currentSlabRate}/unit • '
                'Avg ₨${bill.avgCostPerUnit.toStringAsFixed(2)}/unit',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Consumption summary
          _section(context, '📊 Consumption Summary'),
          _table(context, [
            _row('Total Units', '${bill.totalUnits.toStringAsFixed(1)} kWh', isBold: false),
            _row('Billing Period', '${_fmt(bill.cycleStart)} – ${_fmt(bill.cycleEnd)}', isBold: false),
            _row('Current Slab', 'Slab ${bill.currentSlab} (${_slabLabel(bill.currentSlab)})', isBold: false),
            _row('Current Slab Rate', '₨${bill.currentSlabRate}/unit', isBold: false),
            _row('Average Rate', '₨${bill.avgCostPerUnit.toStringAsFixed(2)}/unit', isBold: false),
          ]),
          const SizedBox(height: 16),

          // Energy charges
          _section(context, '⚡ Energy Charges'),
          _table(context, [
            ..._slabRows(context, tariff.slabs, bill.totalUnits, fmt),
            _row('Energy Charges Total', '₨${fmt.format(bill.energyCharges)}', isBold: true, color: AppColors.primary),
          ]),
          const SizedBox(height: 16),

          // Utility charges
          _section(context, '🏢 Utility Charges'),
          _table(context, [
            _row('Fixed Charges', '₨${fmt.format(bill.fixedCharges)}'),
            _row('FPA (${tariff.fpaRate}/unit × ${bill.totalUnits.toStringAsFixed(0)} units)', '₨${fmt.format(bill.fpaCharges)}'),
            _row('QTA (${tariff.qtaRate}/unit × ${bill.totalUnits.toStringAsFixed(0)} units)', '₨${fmt.format(bill.qtaCharges)}'),
            _row('FC Surcharge (${tariff.fcSurcharge}/unit)', '₨${fmt.format(bill.fcSurcharge)}'),
            _row('Utility Sub-total', '₨${fmt.format(utilitySubtotal)}', isBold: true, color: AppColors.primary),
          ]),
          const SizedBox(height: 16),

          // Government charges
          _section(context, '🏛️ Government Charges & Taxes'),
          _table(context, [
            _row('GST (${tariff.gstPercent}%)', '₨${fmt.format(bill.taxes * 0.55)}'),
            _row('Income Tax (${tariff.incomeTaxPercent}%)', '₨${fmt.format(bill.taxes * 0.25)}'),
            _row('Electricity Duty (${tariff.electricityDuty}%)', '₨${fmt.format(bill.taxes * 0.12)}'),
            _row('TV Fee', '₨${fmt.format(tariff.tvFee)}'),
            _row('Government Sub-total', '₨${fmt.format(govSubtotal)}', isBold: true, color: AppColors.primary),
          ]),
          const SizedBox(height: 16),

          // Final payable
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              _summaryRow(context, 'Utility Sub-total', utilitySubtotal, fmt),
              _summaryRow(context, 'Government Charges', govSubtotal, fmt),
              const Divider(height: 20),
              Row(children: [
                const Expanded(
                  child: Text('TOTAL ESTIMATED PAYABLE',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                Text('₨${fmt0.format(bill.estimatedTotal.toInt())}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ]),
              const SizedBox(height: 4),
              Text('Due within 15 days of bill issue',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ]),
          ),
          const SizedBox(height: 20),

          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Tariff'),
                onPressed: () => context.go('/tariff'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calculate_outlined, size: 16),
                label: const Text('Calculator'),
                onPressed: () => context.go('/cost-calculator'),
              ),
            ),
          ]),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _table(BuildContext context, List<Map<String, dynamic>> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final r = e.value;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(children: [
                Expanded(
                  child: Text(r['label'] as String,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: r['bold'] == true
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: r['bold'] == true
                              ? AppColors.textPrimary
                              : AppColors.textSecondary)),
                ),
                Text(r['value'] as String,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: r['bold'] == true
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: r['color'] as Color? ?? AppColors.textPrimary)),
              ]),
            ),
            if (e.key < rows.length - 1) const Divider(height: 1),
          ]);
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _row(String label, String value,
      {bool isBold = false, Color? color}) {
    return {'label': label, 'value': value, 'bold': isBold, 'color': color};
  }

  List<Map<String, dynamic>> _slabRows(BuildContext context,
      List<dynamic> slabs, double totalUnits, NumberFormat fmt) {
    final rows = <Map<String, dynamic>>[];
    double remaining = totalUnits;
    for (final slab in slabs) {
      if (remaining <= 0) break;
      final slabStart = slab.fromUnits.toDouble();
      final slabEnd = slab.toUnits == 99999 ? totalUnits : slab.toUnits.toDouble();
      final unitsInSlab = (slabEnd - slabStart).clamp(0.0, remaining);
      if (unitsInSlab <= 0) continue;
      final charge = unitsInSlab * slab.ratePerUnit;
      remaining -= unitsInSlab;
      rows.add(_row(
        '${slab.label} × ₨${slab.ratePerUnit}',
        '₨${fmt.format(charge)}',
      ));
    }
    return rows;
  }

  Widget _summaryRow(BuildContext context, String label, double val, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text('₨${fmt.format(val)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  String _slabLabel(int slab) {
    const labels = {
      1: '0–100 units', 2: '101–200', 3: '201–300', 4: '301–400',
      5: '401–500', 6: '501–600', 7: '601–700', 8: '701+',
    };
    return labels[slab] ?? 'Slab $slab';
  }
}
