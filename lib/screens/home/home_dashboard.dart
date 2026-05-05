import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_models/response/weather_response.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/charts/phase_line_chart.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/time_filter_bar.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  TimeFilter _timeFilter = TimeFilter.today;
  WeatherData? weatherData;
  bool isLoadingWeather = true;
  String errorMessage = '';

  int _chartKey = 0;
  final String baseUrl = 'http://3.231.62.206:5000/api/v1';


  @override
  void initState() {
    super.initState();
    print('🔵 HomeDashboard initState START');
    _loadWeatherData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔵 Post frame callback - calling fetchEnergyData');

      final provider = context.read<AppProvider>();
      provider.fetchEnergyData(_timeFilter);
    });
    print('🔵 Calling _loadWeatherData from initState');

    print('🔵 HomeDashboard initState END');
  }

  Future<void> _loadWeatherData() async {
    print('🌤️ _loadWeatherData STARTED');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      print('🌤️ Token found: ${token != null ? 'YES' : 'NO'}');
      print('🌤️ Full URL: $baseUrl/weather?latitude=33.6844&longitude=73.0479');

      if (token == null) {
        print('Token not found');
        setState(() {
          isLoadingWeather = false;
          errorMessage = 'Token not found';
        });
        return;
      }

      print('Weather API Call Start...');
      print('🌤️ Making HTTP GET request to weather API...');


      // API call - Latitude aur longitude ke saath
      final response = await http.get(
        Uri.parse('$baseUrl/weather?latitude=33.6844&longitude=73.0479'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final weatherResponse = WeatherResponse.fromJson(jsonDecode(response.body));

        print('Weather API Success');
        print('Response: ${response.body}');
        if (!mounted) return;

        if (weatherResponse.data != null) {
          setState(() {
            weatherData = weatherResponse.data;
            isLoadingWeather = false;
          });

          print(' Temperature: ${weatherData?.currentWeather?.temperature}°C');
          print(' Wind Speed: ${weatherData?.currentWeather?.windspeed} km/h');
          print(' Timezone: ${weatherData?.timezone}');
        } else {
          setState(() {
            isLoadingWeather = false;
            errorMessage = 'No weather data';
          });
        }
      } else {
        print(' Weather API Error: ${response.statusCode}');
        setState(() {
          isLoadingWeather = false;
          errorMessage = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print(' Exception: ${e.toString()}');
      setState(() {
        isLoadingWeather = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final home = provider.selectedHome;
    final meters = provider.metersForSelectedHome;
    final bill = provider.billEstimate;
    final alerts = provider.alertsForSelectedHome;
    final reading = meters.isNotEmpty ? meters.first.latestReading : null;

    final realtimeData = provider.realtimeData;
    final isLoading = provider.isLoading;

    final powerData = provider.getHistoricalData(
        ParameterType.power,
        _timeFilter,
        MeterType.threePhase
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.cardWhite,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () => _showHomeSelector(context, provider),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(home.name,
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down,
                                  size: 18, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (provider.isSocketConnected)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: const Icon(Icons.wifi, size: 16, color: Colors.green),
                    ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.go('/alerts'),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Weather & Status Row ───────────────────────────
                  _weatherCard(context, home),
                  const SizedBox(height: 16),

                  // ── Time Filter ───────────────────────────────────
                  TimeFilterBar(
                    selected: _timeFilter,
                    onChanged: (f) async {
                      setState(() {
                        _timeFilter = f;
                      });
                      await provider.fetchEnergyData(f);
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── KPI Cards ────────────────────────────────────
                  if (reading != null) ...[
                    SectionHeader(
                      title: 'Today Overview',
                      action: 'Details',
                      onAction: () => context.go('/usage'),
                    ),
                    const SizedBox(height: 12),
                    _kpiGrid(context, reading, bill, realtimeData),
                    const SizedBox(height: 20),
                  ],

                  // ── Live Power Chart ──────────────────────────────
                  SectionHeader(
                    title: 'Live Powers (kW)',
                    action: 'Full Graph',
                    onAction: () => context.go('/parameter/power'),
                  ),
                  const SizedBox(height: 12),
                  _buildChartSection(
                    context: context,
                    timeFilter: _timeFilter,
                    powerData: powerData,
                    isLoading: isLoading,
                    chartKey: _chartKey,
                  ),
                  const SizedBox(height: 20),

                  // ── Cost Snapshot ─────────────────────────────────
                  SectionHeader(
                    title: 'Cost Snapshot',
                    action: 'View Bill',
                    onAction: () => context.go('/cost'),
                  ),
                  const SizedBox(height: 12),
                  _costCard(context, bill),
                  const SizedBox(height: 20),

                  // ── Meters ────────────────────────────────────────
                  SectionHeader(
                    title: 'Meters',
                    action: 'All Meters',
                    onAction: () => context.go('/meters'),
                  ),
                  const SizedBox(height: 12),
                  ...meters.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _meterCard(context, m),
                  )),
                  const SizedBox(height: 20),

                  // ── Alerts ────────────────────────────────────────
                  if (alerts.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Recent Alerts',
                      action: 'All Alerts',
                      onAction: () => context.go('/alerts'),
                    ),
                    const SizedBox(height: 12),
                    ...alerts.take(3).map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _alertTile(context, a),
                    )),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildChartSection({
    required BuildContext context,
    required TimeFilter timeFilter,
    required List<PhaseDataPoint> powerData,
    required bool isLoading,
    required int chartKey,
  }) {
    final isLive = timeFilter == TimeFilter.live;
    final title = isLive ? 'Live Power (kW)' : 'Power History (kW)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: isLoading && powerData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : powerData.isEmpty
              ? const Center(
            child: Text(
              'No data available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
              : PhaseLineChart(
            key: ValueKey('chart_$chartKey'),
            data: powerData,
            parameter: ParameterType.power,
            showPhase1: true,
            showPhase2: true,
            showPhase3: true,
            showTotal: true,
          ),
        ),
        const SizedBox(height: 8),
        PhaseLegend(
          showP1: true,
          showP2: true,
          showP3: true,
          showTotal: true,
          isThreePhase: true,
          onChanged: (_) {},
        ),
        if (isLive)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live updates every 5 seconds',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _weatherCard(BuildContext context, HomeModel home) {
    // Show loading state while weather is being fetched
    if (isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Loading weather...', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show error state
    if (weatherData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weather unavailable', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(errorMessage, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show weather data
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weatherData!.timezone,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${weatherData!.currentWeather!.temperature.toStringAsFixed(1)}°',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                          'Outdoor',
                          style: TextStyle(color: Colors.white70, fontSize: 12)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  StatusChip(
                      label: '${context.watch<AppProvider>().metersForSelectedHome.where((m) => m.status == MeterStatus.online).length} Online',
                      color: AppColors.normalGreen
                  ),
                  const SizedBox(width: 6),
                  StatusChip(
                      label: '${context.watch<AppProvider>().activeAlertCount} Alerts',
                      color: AppColors.warningAmber
                  ),
                ]),
              ],
            ),
          ),
          Text(home.weatherIcon, style: const TextStyle(fontSize: 56)),
        ],
      ),
    );
  }

  Widget _kpiGrid(BuildContext context, MeterReading reading, BillEstimate? bill, Map<String, dynamic>? realtimeData) {
    // Use realtime data if available
    final power = realtimeData?['threePhase']?['power'] ?? reading.power.total;
    final currentPower = realtimeData?['threePhase']?['current'] ?? reading.current.total;
    final voltage = realtimeData?['threePhase']?['voltage'] ?? reading.voltage.total;

    final items = [
      ('Energy Today', '${reading.energyKwh.total.toStringAsFixed(1)} kWh', Icons.bolt, AppColors.phase1),
      ('Voltage', '${voltage.toStringAsFixed(0)} V', Icons.electric_bolt, const Color(0xFF8B5CF6)),
      ('Current', '${currentPower.toStringAsFixed(1)} A', Icons.electrical_services, AppColors.warningAmber),
      ('Active Power', '${power.toStringAsFixed(2)} kW', Icons.power, AppColors.criticalRed),
      ('Est. Bill', '₨${NumberFormat('#,##0').format(bill?.estimatedTotal.toInt() ?? 0)}', Icons.payments, AppColors.normalGreen),
      ('Avg Rate', '₨${bill?.avgCostPerUnit.toStringAsFixed(2) ?? '0.00'}/unit', Icons.price_change, const Color(0xFF10B981)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.$4.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.$3, color: item.$4, size: 20),
              ),
              const SizedBox(height: 16),
              Text(item.$2,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(item.$1,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _costCard(BuildContext context, BillEstimate bill) {
    final progress = (bill.estimatedTotal / bill.budget).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Estimated Bill',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('₨${NumberFormat('#,##0').format(bill.estimatedTotal.toInt())}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Projected',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('₨${NumberFormat('#,##0').format(bill.projectedBill.toInt())}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: bill.projectedBill > bill.budget
                            ? AppColors.criticalRed
                            : AppColors.normalGreen)),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Slab ${bill.currentSlab} • ₨${bill.currentSlabRate}/unit',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text('Budget: ₨${NumberFormat('#,##0').format(bill.budget.toInt())}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                  progress > 1.0 ? AppColors.criticalRed : AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meterCard(BuildContext context, MeterModel meter) {
    return GestureDetector(
      onTap: () => context.go('/meters/${meter.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: meter.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.electric_meter_outlined,
                  color: meter.status.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(meter.name, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(width: 6),
                  StatusChip(label: meter.status.label, color: meter.status.color),
                ]),
                const SizedBox(height: 2),
                Text(
                  '${meter.type == MeterType.threePhase ? "3-Phase" : "1-Phase"} • ${meter.role}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${meter.latestReading.power.total.toStringAsFixed(2)} kW',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${meter.latestReading.energyKwh.total.toStringAsFixed(1)} kWh today',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _alertTile(BuildContext context, AlertModel alert) {
    return GestureDetector(
      onTap: () => context.go('/alerts/${alert.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: alert.severity.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: alert.severity.color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(alert.description,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Text(
              _timeAgo(alert.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showHomeSelector(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Home', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Home'),
                  onPressed: () { Navigator.pop(context); context.go('/add-home'); },
                ),
              ],
            ),
          ),
          ...provider.homes.map((h) => ListTile(
            leading: Icon(
              Icons.home_outlined,
              color: h.id == provider.selectedHomeId
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            title: Text(h.name),
            subtitle: Text(h.city),
            trailing: h.id == provider.selectedHomeId
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () {
              provider.selectHome(h.id);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
