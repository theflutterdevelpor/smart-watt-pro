import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

class TimeFilterBar extends StatelessWidget {
  final TimeFilter selected;
  final ValueChanged<TimeFilter> onChanged;
  final bool includeLive;

  const TimeFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.includeLive = true,
  });

  static const _labels = {
    TimeFilter.live: 'Live',
    TimeFilter.today: 'Today',
    TimeFilter.sevenDays: '7 Days',
    TimeFilter.thirtyDays: '30 Days',
    TimeFilter.billingCycle: 'Billing',
    TimeFilter.custom: 'Custom',
  };

  @override
  Widget build(BuildContext context) {
    final filters = TimeFilter.values.where((f) => includeLive || f != TimeFilter.live).toList();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: filters.length,
        separatorBuilder: (context, state) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isSelected = f == selected;
          return GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                _labels[f]!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
