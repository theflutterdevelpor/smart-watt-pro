import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const SmartWattProApp(),
    ),
  );
}

class SmartWattProApp extends StatefulWidget {
  const SmartWattProApp({super.key});

  @override
  State<SmartWattProApp> createState() => _SmartWattProAppState();
}

class _SmartWattProAppState extends State<SmartWattProApp> {
  late final _router = createRouter(context.read<AppProvider>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Watt Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
