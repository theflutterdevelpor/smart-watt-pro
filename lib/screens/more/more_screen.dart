import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.realtimeData?['user'];
    final home = provider.selectedHome;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('More')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile card
            Container(
              color: AppColors.cardWhite,
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(user.email,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ]),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                  onPressed: () {},
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // Selected Home
            _sectionCard(context, [
              _tile(context, Icons.home_outlined, 'Selected Home', home.name,
                  trailing: const Icon(Icons.keyboard_arrow_right, color: AppColors.textTertiary),
                  onTap: () {}),
            ]),
            const SizedBox(height: 12),

            // Homes & Meters
            _groupHeader(context, 'Homes & Meters'),
            _sectionCard(context, [
              _tile(context, Icons.home_work_outlined, 'My Homes', '${provider.homes.length} homes',
                  onTap: () {}),
              _divider(),
              _tile(context, Icons.electric_meter_outlined, 'All Meters',
                  '${provider.allMeters.length} meters connected',
                  onTap: () => context.go('/meters')),
              _divider(),
              _tile(context, Icons.add_home_outlined, 'Add Home', null,
                  onTap: () => context.go('/add-home')),
              _divider(),
              _tile(context, Icons.add_circle_outline, 'Add Meter', null,
                  onTap: () => context.go('/add-meter')),
            ]),
            const SizedBox(height: 12),

            // Energy Settings
            _groupHeader(context, 'Energy Settings'),
            _sectionCard(context, [
              _tile(context, Icons.receipt_long_outlined, 'Tariff Settings', null,
                  onTap: () => context.go('/tariff')),
              _divider(),
              _tile(context, Icons.tune, 'Thresholds & Alerts', null,
                  onTap: () => context.go('/thresholds')),
              _divider(),
              _tile(context, Icons.calculate_outlined, 'Cost Calculator', null,
                  onTap: () => context.go('/cost-calculator')),
              _divider(),
              _tile(context, Icons.assessment_outlined, 'Reports', null,
                  onTap: () {}),
            ]),
            const SizedBox(height: 12),

            // Account
            _groupHeader(context, 'Account'),
            _sectionCard(context, [
              _tile(context, Icons.notifications_outlined, 'Notification Settings', null,
                  onTap: () {}),
              _divider(),
              _tile(context, Icons.security_outlined, 'Privacy & Security', null,
                  onTap: () {}),
            ]),
            const SizedBox(height: 12),

            // Support
            _groupHeader(context, 'Support'),
            _sectionCard(context, [
              _tile(context, Icons.help_outline, 'Help Center', null, onTap: () {}),
              _divider(),
              _tile(context, Icons.contact_support_outlined, 'Contact Support', null,
                  onTap: () {}),
            ]),
            const SizedBox(height: 12),

            // App
            _sectionCard(context, [
              _tile(context, Icons.policy_outlined, 'Privacy Policy', null, onTap: () {}),
              _divider(),
              _tile(context, Icons.description_outlined, 'Terms of Service', null,
                  onTap: () {}),
              _divider(),
              _tile(context, Icons.logout, 'Logout', null,
                  color: AppColors.criticalRed,
                  onTap: () {
                    provider.logout();
                    context.go('/login');
                  }),
            ]),

            const SizedBox(height: 24),
            Text('Smart Watt Pro v1.0.0',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, List<Widget> children) {
    return Container(
      color: AppColors.cardWhite,
      child: Column(children: children),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String? subtitle, {
    Widget? trailing,
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
      title: Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? AppColors.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: trailing ??
          const Icon(Icons.keyboard_arrow_right, color: AppColors.textTertiary),
      onTap: onTap,
      dense: subtitle == null,
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 54);
}
