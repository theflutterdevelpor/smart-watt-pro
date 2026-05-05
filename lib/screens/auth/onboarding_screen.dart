import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.home_outlined, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text("Let's Get Started", style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(
                'Add your home and smart energy meter to begin real-time monitoring.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              _stepCard(
                context,
                icon: Icons.add_home_outlined,
                color: AppColors.primary,
                title: 'Add Your Home',
                subtitle: 'Enter address, city, and location for weather data',
              ),
              const SizedBox(height: 16),
              _stepCard(
                context,
                icon: Icons.electric_meter_outlined,
                color: AppColors.secondary,
                title: 'Connect Your Meter',
                subtitle: 'Scan QR or enter meter ID — single or three phase',
              ),
              const SizedBox(height: 16),
              _stepCard(
                context,
                icon: Icons.receipt_long_outlined,
                color: AppColors.tertiary,
                title: 'Set Tariff & Budget',
                subtitle: 'Choose DISCO, tariff type, and monthly budget',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/add-home'),
                  child: const Text('Add Home & Meter'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AppProvider>().completeOnboarding();
                    context.go('/');
                  },
                  child: const Text('Skip for Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
