import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/mock/mock_data.dart';
import '../services/auth_services.dart';
import '../services/device_service.dart';
import '../services/energy_services.dart';
import '../services/energy_sockets.dart';

class AppProvider extends ChangeNotifier {

  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final EnergyService _energyService = EnergyService();
  final DeviceService _deviceService = DeviceService();

  // Auth state
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  // Loading and error state
  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Realtime data
  Map<String, dynamic>? _realtimeData;
  Map<String, dynamic>? get realtimeData => _realtimeData;

  bool get isSocketConnected => _socketService.connected;


  // Historical data cache
  final Map<ParameterType, List<PhaseDataPoint>> _historicalData = {};

  List<HomeModel> _homes = [];
  String _selectedHomeId = '';

  // Homes
  List<HomeModel> get homes => _homes;
  HomeModel get selectedHome {
    if (_homes.isEmpty) return HomeModel.empty();
    try {
      return _homes.firstWhere((h) => h.id == _selectedHomeId);
    } catch (e) {
      return _homes.first;
    }
  }


  void selectHome(String id) {
    if (_selectedHomeId == id) return;

    _selectedHomeId = id;
    _historicalData.clear();

    // Reload data for new home
    Future.wait([
      fetchEnergyData(TimeFilter.today),
    ]);

    notifyListeners();
  }

  String get selectedHomeId => _selectedHomeId;

  // Meters
  List<MeterModel> _meters = [];
  List<MeterModel> get allMeters => _meters;
  List<MeterModel> get metersForSelectedHome => _meters;



  MeterModel? getMeterById(String id) =>
      mockMeters.firstWhere((m) => m.id == id, orElse: () => mockMeters.first);

  // Alerts
  List<AlertModel> get allAlerts => mockAlerts;
  List<AlertModel> get activeAlerts =>
      mockAlerts.where((a) => a.status == AlertStatus.active).toList();
  List<AlertModel> get alertsForSelectedHome =>
      mockAlerts.where((a) => a.homeId == _selectedHomeId).toList();

  int get activeAlertCount => activeAlerts.length;

  // Thresholds
  List<ThresholdRule> get allThresholds => mockThresholds;
  List<ThresholdRule> get thresholdsForSelectedHome =>
      mockThresholds.where((t) => t.homeId == _selectedHomeId).toList();

  // Bill
  BillEstimate get billEstimate => mockBillEstimate;

  // Tariff
  TariffVersion get activeTariff => mockTariffVersion;

  final Map<String, TimeFilter> _timeFilters = {};

  TimeFilter getTimeFilter(String screenKey) =>
      _timeFilters[screenKey] ?? TimeFilter.today;

  void setTimeFilter(String screenKey, TimeFilter filter) {
    _timeFilters[screenKey] = filter;
    notifyListeners();
  }







  Future<void> fetchEnergyData(TimeFilter filter) async {
    _setLoading(true);
    _clearError();

    try {
      final dates = _getDateRange(filter);
      Map<String, dynamic> response;

      if (filter == TimeFilter.today) {
        response = await EnergyService.fetchEnergyHourly(
            date: dates['fromDate']!
        );
      } else {
        response = await EnergyService.fetchEnergy(
          fromDate: dates['fromDate']!,
          toDate: dates['toDate']!,
        );
      }

      if (response['success'] == true) {
        final data = response['data'];
        final chartData = _convertToPhaseData(data, filter);
        _historicalData[ParameterType.power] = chartData;
        notifyListeners();
      } else {
        _setError(response['message'] ?? 'Failed to fetch data');
      }

    } catch (e) {
      debugPrint('❌ Error fetching energy data: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Map<String, String> _getDateRange(TimeFilter filter) {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    switch(filter) {
      case TimeFilter.today:
        return {'fromDate': today, 'toDate': today};
      case TimeFilter.sevenDays:
        final sevenDaysAgo = DateTime(now.year, now.month, now.day - 6);
        return {
          'fromDate': '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}',
          'toDate': today
        };
      case TimeFilter.thirtyDays:
        final thirtyDaysAgo = DateTime(now.year, now.month, now.day - 29);
        return {
          'fromDate': '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}',
          'toDate': today
        };
      default:
        return {'fromDate': today, 'toDate': today};
    }
  }

  List<PhaseDataPoint> _convertToPhaseData(Map<String, dynamic> data, TimeFilter filter) {
    final points = <PhaseDataPoint>[];

    final phase1List = (data['phaseOneData'] as List?) ?? [];
    final phase2List = (data['phaseTwoData'] as List?) ?? [];
    final phase3List = (data['phaseThreeData'] as List?) ?? [];
    final threePhaseList = (data['threePhaseData'] as List?) ?? [];

    final isHourly = filter == TimeFilter.today;

    if (phase1List.isEmpty && phase2List.isEmpty && phase3List.isEmpty && threePhaseList.isEmpty) {
      return points;
    }

    final maxLength = [
      phase1List.length,
      phase2List.length,
      phase3List.length,
      threePhaseList.length
    ].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLength; i++) {
      DateTime time;

      if (isHourly) {
        final hourData = phase1List.isNotEmpty ? phase1List[i] : (threePhaseList.isNotEmpty ? threePhaseList[i] : null);
        final hour = hourData != null ? (hourData['hour'] ?? i) : i;
        time = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, 0);
      } else {
        time = DateTime.now().subtract(Duration(days: maxLength - i));
      }

      double getValue(Map<String, dynamic> listItem, String key) {
        if (listItem == null) return 0.0;
        final value = listItem[key];
        if (value == null) return 0.0;
        if (value is int) return value.toDouble();
        if (value is double) return value;
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      final phase1Item = i < phase1List.length ? phase1List[i] : null;
      final phase2Item = i < phase2List.length ? phase2List[i] : null;
      final phase3Item = i < phase3List.length ? phase3List[i] : null;
      final threePhaseItem = i < threePhaseList.length ? threePhaseList[i] : null;

      points.add(PhaseDataPoint(
        time: time,
        phase1: phase1Item != null ? (isHourly
            ? getValue(phase1Item, 'sumOfEnergyPerHour')
            : getValue(phase1Item, 'dailySumOfEnergy')) : 0,
        phase2: phase2Item != null ? (isHourly
            ? getValue(phase2Item, 'sumOfEnergyPerHour')
            : getValue(phase2Item, 'dailySumOfEnergy')) : 0,
        phase3: phase3Item != null ? (isHourly
            ? getValue(phase3Item, 'sumOfEnergyPerHour')
            : getValue(phase3Item, 'dailySumOfEnergy')) : 0,
        total: threePhaseItem != null ? (isHourly
            ? getValue(threePhaseItem, 'sumOfEnergyPerHour')
            : getValue(threePhaseItem, 'dailySumOfEnergy')) : 0,
      ));
    }

    return points;
  }


  // MARK: - Real-time Socket Methods

  void connectSocket() async {
    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      _socketService.connect(token);
      _setupSocketListeners();
    }
  }

  void disconnectSocket() {
    _socketService.disconnect();
  }

  void _setupSocketListeners() {
    _socketService.on('realtime-data', (data) {
      _realtimeData = data;
      notifyListeners();
    });

    _socketService.on('alert', (data) {
      // New alert aane par
      debugPrint('New alert: $data');
      notifyListeners();
    });
  }

  // MARK: - Get Historical Data (with cache)

  List<PhaseDataPoint> getHistoricalData(
      ParameterType param, TimeFilter filter, MeterType meterType) {

    // Check cache first
    if (_historicalData.containsKey(param)) {
      return _historicalData[param]!;
    }

    // Agar cache mein nahi hai toh fetch karo
    fetchEnergyData(filter);

    // Tab tak mock data return karo
    return generateHistoricalData(param, filter, meterType);
  }

  // MARK: - Auth actions
  void login() {
    _isLoggedIn = true;
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    disconnectSocket();
    _historicalData.clear();
    _realtimeData = null;
    notifyListeners();
  }

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  // MARK: - Helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}