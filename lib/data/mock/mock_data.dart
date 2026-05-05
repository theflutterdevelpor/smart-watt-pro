import 'dart:math';
import '../models/models.dart';

final _rand = Random(42);

double _jitter(double base, double pct) => base + base * (_rand.nextDouble() - 0.5) * pct;

List<PhaseDataPoint> generateHistoricalData(
    ParameterType param, TimeFilter filter, MeterType meterType) {
  final now = DateTime.now();
  final points = <PhaseDataPoint>[];

  late int count;
  late Duration step;

  switch (filter) {
    case TimeFilter.live:
      count = 30;
      step = const Duration(minutes: 1);
      break;
    case TimeFilter.today:
      count = 24;
      step = const Duration(hours: 1);
      break;
    case TimeFilter.sevenDays:
      count = 7 * 24;
      step = const Duration(hours: 1);
      break;
    case TimeFilter.thirtyDays:
      count = 30;
      step = const Duration(days: 1);
      break;
    case TimeFilter.billingCycle:
      count = 30;
      step = const Duration(days: 1);
      break;
    case TimeFilter.custom:
      count = 30;
      step = const Duration(days: 1);
      break;
  }

  late double b1, b2, b3;
  switch (param) {
    case ParameterType.voltage:
      b1 = 230; b2 = 228; b3 = 232;
      break;
    case ParameterType.current:
      b1 = 8.5; b2 = 7.2; b3 = 9.1;
      break;
    case ParameterType.power:
      b1 = 1.95; b2 = 1.64; b3 = 2.09;
      break;
    case ParameterType.activePower:
      b1 = 1.85; b2 = 1.55; b3 = 1.98;
      break;
    case ParameterType.reactivePower:
      b1 = 0.45; b2 = 0.38; b3 = 0.51;
      break;
    case ParameterType.energyConsumption:
      b1 = 12.4; b2 = 10.8; b3 = 13.6;
      break;
    case ParameterType.powerFactor:
      b1 = 0.92; b2 = 0.89; b3 = 0.94;
      break;
    case ParameterType.frequency:
      b1 = 50.0; b2 = 49.9; b3 = 50.1;
      break;
    case ParameterType.peakDemand:
      b1 = 3.2; b2 = 2.8; b3 = 3.5;
      break;
    case ParameterType.cost:
      b1 = 450; b2 = 390; b3 = 495;
      break;
    case ParameterType.costPerUnit:
      b1 = 29.5; b2 = 29.5; b3 = 29.5;
      break;
  }

  for (int i = count - 1; i >= 0; i--) {
    final t = now.subtract(step * i);
    final p1 = _jitter(b1, 0.08);
    final p2 = _jitter(b2, 0.08);
    final p3 = _jitter(b3, 0.08);
    double total;
    if (param == ParameterType.voltage || param == ParameterType.frequency ||
        param == ParameterType.powerFactor || param == ParameterType.costPerUnit) {
      total = (p1 + p2 + p3) / 3;
    } else {
      total = p1 + p2 + p3;
    }
    points.add(PhaseDataPoint(time: t, phase1: p1, phase2: p2, phase3: p3, total: total));
  }
  return points;
}

// ── Mock Tariff ──────────────────────────────────────────────────────────

final mockTariffVersion = TariffVersion(
  id: 'tv_1',
  provider: 'IESCO',
  tariffType: TariffType.nonProtected,
  method: TariffMethod.slab,
  effectiveFrom: DateTime(2024, 1, 1),
  isStandard: true,
  versionNote: 'FY 2024-25 Revised',
  slabs: const [
    TariffSlab(fromUnits: 0, toUnits: 100, ratePerUnit: 7.74, label: '0–100 units'),
    TariffSlab(fromUnits: 101, toUnits: 200, ratePerUnit: 10.06, label: '101–200 units'),
    TariffSlab(fromUnits: 201, toUnits: 300, ratePerUnit: 15.09, label: '201–300 units'),
    TariffSlab(fromUnits: 301, toUnits: 400, ratePerUnit: 20.39, label: '301–400 units'),
    TariffSlab(fromUnits: 401, toUnits: 500, ratePerUnit: 22.65, label: '401–500 units'),
    TariffSlab(fromUnits: 501, toUnits: 600, ratePerUnit: 25.09, label: '501–600 units'),
    TariffSlab(fromUnits: 601, toUnits: 700, ratePerUnit: 29.33, label: '601–700 units'),
    TariffSlab(fromUnits: 701, toUnits: 99999, ratePerUnit: 35.00, label: '701+ units'),
  ],
  fixedCharge: 150.0,
  fpaRate: 2.50,
  qtaRate: 0.35,
  fcSurcharge: 3.23,
  njSurcharge: 0.10,
  gstPercent: 18.0,
  incomeTaxPercent: 7.5,
  electricityDuty: 1.5,
  tvFee: 35.0,
  peakRate: 38.0,
  offPeakRate: 18.0,
);

// ── Mock Readings ──────────────────────────────────────────────────────────

MeterReading get mockReading3Phase => MeterReading(
  meterId: 'm_1',
  timestamp: DateTime.now(),
  voltage: const PhaseValues(phase1: 231.5, phase2: 228.3, phase3: 233.1, total: 230.97),
  current: const PhaseValues(phase1: 8.7, phase2: 7.4, phase3: 9.2, total: 25.3),
  power: const PhaseValues(phase1: 2.01, phase2: 1.69, phase3: 2.15, total: 5.85),
  activePower: const PhaseValues(phase1: 1.90, phase2: 1.60, phase3: 2.04, total: 5.54),
  reactivePower: const PhaseValues(phase1: 0.47, phase2: 0.40, phase3: 0.53, total: 1.40),
  energyKwh: const PhaseValues(phase1: 12.8, phase2: 11.2, phase3: 14.1, total: 38.1),
  powerFactor: const PhaseValues(phase1: 0.92, phase2: 0.88, phase3: 0.93, total: 0.91),
  frequency: const PhaseValues(phase1: 50.02, phase2: 49.98, phase3: 50.05, total: 50.02),
  peakDemand: const PhaseValues(phase1: 3.4, phase2: 2.9, phase3: 3.7, total: 10.0),
  estimatedCost: const PhaseValues(phase1: 462.0, phase2: 403.0, phase3: 508.0, total: 1373.0),
);

MeterReading get mockReadingSinglePhase => MeterReading(
  meterId: 'm_2',
  timestamp: DateTime.now(),
  voltage: const PhaseValues(phase1: 229.8, phase2: 0, phase3: 0, total: 229.8),
  current: const PhaseValues(phase1: 6.2, phase2: 0, phase3: 0, total: 6.2),
  power: const PhaseValues(phase1: 1.42, phase2: 0, phase3: 0, total: 1.42),
  activePower: const PhaseValues(phase1: 1.35, phase2: 0, phase3: 0, total: 1.35),
  reactivePower: const PhaseValues(phase1: 0.33, phase2: 0, phase3: 0, total: 0.33),
  energyKwh: const PhaseValues(phase1: 8.5, phase2: 0, phase3: 0, total: 8.5),
  powerFactor: const PhaseValues(phase1: 0.94, phase2: 0, phase3: 0, total: 0.94),
  frequency: const PhaseValues(phase1: 49.99, phase2: 0, phase3: 0, total: 49.99),
  peakDemand: const PhaseValues(phase1: 2.1, phase2: 0, phase3: 0, total: 2.1),
  estimatedCost: const PhaseValues(phase1: 285.0, phase2: 0, phase3: 0, total: 285.0),
);

// ── Mock Meters ──────────────────────────────────────────────────────────

final mockMeters = [
  MeterModel(
    id: 'm_1',
    homeId: 'h_1',
    name: 'Main Meter',
    meterId: 'SWP-001-3P',
    type: MeterType.threePhase,
    role: 'Main Supply',
    status: MeterStatus.online,
    lastSyncAt: DateTime.now().subtract(const Duration(seconds: 45)),
    latestReading: mockReading3Phase,
  ),
  MeterModel(
    id: 'm_2',
    homeId: 'h_1',
    name: 'Solar Meter',
    meterId: 'SWP-002-1P',
    type: MeterType.singlePhase,
    role: 'Solar Import',
    status: MeterStatus.online,
    lastSyncAt: DateTime.now().subtract(const Duration(seconds: 60)),
    latestReading: mockReadingSinglePhase,
  ),
  MeterModel(
    id: 'm_3',
    homeId: 'h_2',
    name: 'Main Meter',
    meterId: 'SWP-003-3P',
    type: MeterType.threePhase,
    role: 'Main Supply',
    status: MeterStatus.warning,
    lastSyncAt: DateTime.now().subtract(const Duration(minutes: 8)),
    latestReading: mockReading3Phase,
  ),
];

// ── Mock Homes ────────────────────────────────────────────────────────────

final mockHomes = [
  const HomeModel(
    id: 'h_1',
    name: 'Main Home',
    type: 'Residential',
    address: '12-A, Model Town',
    city: 'Lahore',
    province: 'Punjab',
    country: 'Pakistan',
    lat: 31.4826,
    lng: 74.3282,
    timezone: 'Asia/Karachi',
    outdoorTemp: 32.0,
    weatherIcon: '☀️',
    disco: 'LESCO',
    tariffType: TariffType.nonProtected,
    billingCycleDay: 1,
    monthlyBudget: 8000,
    meterIds: ['m_1', 'm_2'],
  ),
  const HomeModel(
    id: 'h_2',
    name: "Parents' Home",
    type: 'Residential',
    address: '5-B, Gulberg III',
    city: 'Lahore',
    province: 'Punjab',
    country: 'Pakistan',
    lat: 31.5204,
    lng: 74.3587,
    timezone: 'Asia/Karachi',
    outdoorTemp: 33.0,
    weatherIcon: '⛅',
    disco: 'LESCO',
    tariffType: TariffType.nonProtected,
    billingCycleDay: 1,
    monthlyBudget: 5000,
    meterIds: ['m_3'],
  ),
];

// ── Mock Alerts ───────────────────────────────────────────────────────────

final mockAlerts = [
  AlertModel(
    id: 'a_1',
    type: 'High Voltage',
    homeId: 'h_1',
    meterId: 'm_1',
    parameter: ParameterType.voltage,
    phaseOrTotal: 'Phase 3',
    actualValue: 248.5,
    thresholdValue: 240.0,
    severity: AlertSeverity.warning,
    status: AlertStatus.active,
    createdAt: DateTime.now().subtract(const Duration(minutes: 23)),
    description: 'Phase 3 voltage exceeded 240V safe limit',
  ),
  AlertModel(
    id: 'a_2',
    type: 'High Energy',
    homeId: 'h_1',
    meterId: 'm_1',
    parameter: ParameterType.energyConsumption,
    phaseOrTotal: 'Total',
    actualValue: 42.3,
    thresholdValue: 40.0,
    severity: AlertSeverity.warning,
    status: AlertStatus.active,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    description: 'Daily energy consumption exceeded 40 kWh',
  ),
  AlertModel(
    id: 'a_3',
    type: 'Low Power Factor',
    homeId: 'h_1',
    meterId: 'm_1',
    parameter: ParameterType.powerFactor,
    phaseOrTotal: 'Phase 2',
    actualValue: 0.78,
    thresholdValue: 0.85,
    severity: AlertSeverity.info,
    status: AlertStatus.acknowledged,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    description: 'Phase 2 power factor below 0.85',
  ),
  AlertModel(
    id: 'a_4',
    type: 'Meter Offline',
    homeId: 'h_2',
    meterId: 'm_3',
    parameter: ParameterType.power,
    phaseOrTotal: 'Total',
    actualValue: 0,
    thresholdValue: 0,
    severity: AlertSeverity.critical,
    status: AlertStatus.active,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    description: "Parents' Home meter connection delayed",
  ),
];

// ── Mock Thresholds ───────────────────────────────────────────────────────

final mockThresholds = [
  const ThresholdRule(
    id: 't_1',
    homeId: 'h_1',
    meterId: 'm_1',
    parameter: ParameterType.energyConsumption,
    phaseOrTotal: 'Total',
    condition: ThresholdCondition.greaterThan,
    value: 40.0,
    durationMinutes: 0,
    severity: AlertSeverity.warning,
    isActive: true,
    isTriggered: true,
  ),
  const ThresholdRule(
    id: 't_2',
    homeId: 'h_1',
    meterId: 'm_1',
    parameter: ParameterType.voltage,
    phaseOrTotal: 'Any Phase',
    condition: ThresholdCondition.outsideRange,
    value: 200.0,
    value2: 240.0,
    durationMinutes: 5,
    severity: AlertSeverity.warning,
    isActive: true,
    isTriggered: true,
  ),
  const ThresholdRule(
    id: 't_3',
    homeId: 'h_1',
    meterId: null,
    parameter: ParameterType.cost,
    phaseOrTotal: 'Total',
    condition: ThresholdCondition.greaterThan,
    value: 8000.0,
    durationMinutes: 0,
    severity: AlertSeverity.warning,
    isActive: true,
    isTriggered: false,
  ),
  const ThresholdRule(
    id: 't_4',
    homeId: 'h_1',
    meterId: 'm_1',
    parameter: ParameterType.power,
    phaseOrTotal: 'Total',
    condition: ThresholdCondition.greaterThan,
    value: 8.0,
    durationMinutes: 10,
    severity: AlertSeverity.warning,
    isActive: true,
    isTriggered: false,
  ),
];

// ── Mock Bill Estimate ────────────────────────────────────────────────────

BillEstimate get mockBillEstimate {
  final now = DateTime.now();
  return BillEstimate(
    homeId: 'h_1',
    cycleStart: DateTime(now.year, now.month, 1),
    cycleEnd: DateTime(now.year, now.month + 1, 0),
    totalUnits: 342.5,
    currentSlab: 4,
    currentSlabRate: 20.39,
    avgCostPerUnit: 18.74,
    energyCharges: 5486.0,
    fixedCharges: 150.0,
    fpaCharges: 856.25,
    qtaCharges: 119.88,
    fcSurcharge: 1106.18,
    taxes: 1463.5,
    estimatedTotal: 9181.81,
    projectedBill: 11420.0,
    budget: 8000.0,
    tariffVersionId: 'tv_1',
  );
}
