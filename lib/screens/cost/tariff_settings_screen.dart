import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class TariffSettingsScreen extends StatelessWidget {
  const TariffSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tariff = context.watch<AppProvider>().activeTariff;
    final home = context.watch<AppProvider>().selectedHome;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tariff Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/more'),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Edit Rates'),
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
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                _row('Home', home.name),
                _row('Provider (DISCO)', tariff.provider),
                _row('Category', 'A-1 Residential'),
                _row('Tariff Type', tariff.tariffType.name.toUpperCase()),
                _row('Method', tariff.method.name.toUpperCase()),
                _row('Rate Source', tariff.isStandard ? 'Standard Rates' : 'Manual Override'),
                _row('Effective From', DateFormat('dd MMM yyyy').format(tariff.effectiveFrom)),
              ]),
            ),
            const SizedBox(height: 20),

            Text('Energy Slabs', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: tariff.slabs.asMap().entries.map((e) {
                  final slab = e.value;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Expanded(
                          child: Text(slab.label,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Text('₨${slab.ratePerUnit}/unit',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ]),
                    ),
                    if (e.key < tariff.slabs.length - 1)
                      const Divider(height: 1),
                  ]);
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Text('Other Charges', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                _chargeRow('Fixed Charge', '₨${tariff.fixedCharge}/month'),
                _chargeRow('FPA', '₨${tariff.fpaRate}/unit (prev month)'),
                _chargeRow('QTA', '₨${tariff.qtaRate}/unit'),
                _chargeRow('FC Surcharge', '₨${tariff.fcSurcharge}/unit'),
                _chargeRow('NJ Surcharge', '₨${tariff.njSurcharge}/unit'),
                _chargeRow('GST', '${tariff.gstPercent}%'),
                _chargeRow('Income Tax', '${tariff.incomeTaxPercent}%'),
                _chargeRow('Electricity Duty', '${tariff.electricityDuty}%'),
                _chargeRow('TV Fee', '₨${tariff.tvFee}/month'),
              ]),
            ),
            const SizedBox(height: 20),

            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Version History'),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Version'),
                  onPressed: () {},
                ),
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _chargeRow(String label, String value) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      const Divider(height: 1),
    ]);
  }
}
