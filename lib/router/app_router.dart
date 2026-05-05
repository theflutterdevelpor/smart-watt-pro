import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_provider.dart';
import '../screens/alerts/alert_detail_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/auth/add_home_screen.dart';
import '../screens/auth/add_meter_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/cost/bill_breakdown_screen.dart';
import '../screens/cost/cost_calculator_screen.dart';
import '../screens/cost/cost_screen.dart';
import '../screens/cost/tariff_settings_screen.dart';
import '../screens/home/home_dashboard.dart';
import '../screens/meters/meter_detail_screen.dart';
import '../screens/meters/meters_list_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/parameter/parameter_comparison_screen.dart';
import '../screens/parameter/parameter_detail_screen.dart';
import '../screens/parameter/parameter_history_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/thresholds/create_threshold_screen.dart';
import '../screens/thresholds/thresholds_screen.dart';
import '../screens/usage/usage_screen.dart';

GoRouter createRouter(AppProvider provider) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loggedIn = provider.isLoggedIn;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/splash';
      if (!loggedIn && !onAuth) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) =>  SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/add-home', builder: (context, state) => const AddHomeScreen()),
      GoRoute(path: '/add-meter', builder: (context, state) => const AddMeterScreen()),
      GoRoute(
        path: '/parameter/:param',
        builder: (_, state) => ParameterDetailScreen(
            paramName: state.pathParameters['param']!),
      ),
      GoRoute(
        path: '/alerts/:id',
        builder: (_, state) =>
            AlertDetailScreen(alertId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/cost', builder: (context, state) => const CostScreen()),
      GoRoute(path: '/bill-breakdown', builder: (context, state) => const BillBreakdownScreen()),
      GoRoute(path: '/cost-calculator', builder: (context, state) => const CostCalculatorScreen()),
      GoRoute(path: '/tariff', builder: (context, state) => const TariffSettingsScreen()),
      GoRoute(path: '/thresholds', builder: (context, state) => const ThresholdsScreen()),
      GoRoute(path: '/thresholds/create', builder: (context, state) => const CreateThresholdScreen()),
      GoRoute(
        path: '/parameter/:param/history',
        builder: (_, state) => ParameterHistoryScreen(
            paramName: state.pathParameters['param']!),
      ),
      GoRoute(
        path: '/parameter/:param/compare',
        builder: (_, state) => ParameterComparisonScreen(
            paramName: state.pathParameters['param']!),
      ),
      GoRoute(
        path: '/meters/:id',
        builder: (_, state) =>
            MeterDetailScreen(meterId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeDashboard()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/meters', builder:(context, state) => const MetersListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/usage', builder: (context, state) => const UsageScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/alerts', builder: (context, state) => const AlertsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', builder: (context, state) => const MoreScreen()),
          ]),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}
