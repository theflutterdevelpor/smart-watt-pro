import 'package:flutter/material.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum MeterType { singlePhase, threePhase }

enum MeterStatus { online, delayed, offline, warning, critical }

enum AlertSeverity { info, warning, critical }

enum AlertStatus { active, acknowledged, resolved, muted }

enum TariffType { lifeline, protected, nonProtected, tou }

enum TariffMethod { slab, flat, timeOfUse }

enum ParameterType {
  energyConsumption,
  voltage,
  current,
  power,
  cost,
  powerFactor,
  frequency,
  peakDemand,
  activePower,
  reactivePower,
  costPerUnit,
}

enum TimeFilter { live, today, sevenDays, thirtyDays, billingCycle, custom }

// ── Value Objects ──────────────────────────────────────────────────────────

class PhaseValues {
  final double phase1;
  final double phase2;
  final double phase3;
  final double total;

  const PhaseValues({
    required this.phase1,
    required this.phase2,
    required this.phase3,
    required this.total,
  });

  double get highest => [phase1, phase2, phase3].reduce((a, b) => a > b ? a : b);
  double get lowest => [phase1, phase2, phase3].reduce((a, b) => a < b ? a : b);
  double get average => (phase1 + phase2 + phase3) / 3;
}

class PhaseDataPoint {
  final DateTime time;
  final double phase1;
  final double phase2;
  final double phase3;
  final double total;

  const PhaseDataPoint({
    required this.time,
    required this.phase1,
    required this.phase2,
    required this.phase3,
    required this.total,
  });
}

// ── User ──────────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String email;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });
}

// ── Home ──────────────────────────────────────────────────────────────────

// ── Home ──────────────────────────────────────────────────────────────────

class HomeModel {
  final String id;
  final String name;
  final String type;
  final String address;
  final String city;
  final String province;
  final String country;
  final double lat;
  final double lng;
  final String timezone;
  final double outdoorTemp;
  final String weatherIcon;
  final String disco;
  final TariffType tariffType;
  final int billingCycleDay;
  final double monthlyBudget;
  final List<String> meterIds;

  const HomeModel({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    required this.province,
    required this.country,
    required this.lat,
    required this.lng,
    required this.timezone,
    required this.outdoorTemp,
    required this.weatherIcon,
    required this.disco,
    required this.tariffType,
    required this.billingCycleDay,
    required this.monthlyBudget,
    required this.meterIds,
  });

  // ✅ ADD THIS EMPTY CONSTRUCTOR
  factory HomeModel.empty() {
    return HomeModel(
      id: '',
      name: 'My Home',
      type: 'residential',
      address: '',
      city: 'Karachi',
      province: 'Sindh',
      country: 'Pakistan',
      lat: 0.0,
      lng: 0.0,
      timezone: 'Asia/Karachi',
      outdoorTemp: 25.0,
      weatherIcon: '☀️',
      disco: 'K-Electric',
      tariffType: TariffType.nonProtected,
      billingCycleDay: 1,
      monthlyBudget: 10000,
      meterIds: const [],
    );
  }
}

// ── Meter ──────────────────────────────────────────────────────────────────

class MeterModel {
  final String id;
  final String homeId;
  final String name;
  final String meterId;
  final MeterType type;
  final String role;
  final MeterStatus status;
  final DateTime lastSyncAt;
  final MeterReading latestReading;

  const MeterModel({
    required this.id,
    required this.homeId,
    required this.name,
    required this.meterId,
    required this.type,
    required this.role,
    required this.status,
    required this.lastSyncAt,
    required this.latestReading,
  });
}





// ── Meter Reading ──────────────────────────────────────────────────────────

class MeterReading {
  final String meterId;
  final DateTime timestamp;
  final PhaseValues voltage;
  final PhaseValues current;
  final PhaseValues power;
  final PhaseValues activePower;
  final PhaseValues reactivePower;
  final PhaseValues energyKwh;
  final PhaseValues powerFactor;
  final PhaseValues frequency;
  final PhaseValues peakDemand;
  final PhaseValues estimatedCost;

  const MeterReading({
    required this.meterId,
    required this.timestamp,
    required this.voltage,
    required this.current,
    required this.power,
    required this.activePower,
    required this.reactivePower,
    required this.energyKwh,
    required this.powerFactor,
    required this.frequency,
    required this.peakDemand,
    required this.estimatedCost,
  });

  PhaseValues valuesFor(ParameterType param) {
    switch (param) {
      case ParameterType.voltage: return voltage;
      case ParameterType.current: return current;
      case ParameterType.power: return power;
      case ParameterType.activePower: return activePower;
      case ParameterType.reactivePower: return reactivePower;
      case ParameterType.energyConsumption: return energyKwh;
      case ParameterType.powerFactor: return powerFactor;
      case ParameterType.frequency: return frequency;
      case ParameterType.peakDemand: return peakDemand;
      case ParameterType.cost: return estimatedCost;
      case ParameterType.costPerUnit: return estimatedCost;
    }
  }
}

// ── Tariff ──────────────────────────────────────────────────────────────────

class TariffSlab {
  final int fromUnits;
  final int toUnits;
  final double ratePerUnit;
  final String label;

  const TariffSlab({
    required this.fromUnits,
    required this.toUnits,
    required this.ratePerUnit,
    required this.label,
  });
}

class TariffVersion {
  final String id;
  final String provider;
  final TariffType tariffType;
  final TariffMethod method;
  final DateTime effectiveFrom;
  final bool isStandard;
  final String? versionNote;
  final List<TariffSlab> slabs;
  final double fixedCharge;
  final double fpaRate;
  final double qtaRate;
  final double fcSurcharge;
  final double njSurcharge;
  final double gstPercent;
  final double incomeTaxPercent;
  final double electricityDuty;
  final double tvFee;
  final double peakRate;
  final double offPeakRate;

  const TariffVersion({
    required this.id,
    required this.provider,
    required this.tariffType,
    required this.method,
    required this.effectiveFrom,
    required this.isStandard,
    this.versionNote,
    required this.slabs,
    required this.fixedCharge,
    required this.fpaRate,
    required this.qtaRate,
    required this.fcSurcharge,
    required this.njSurcharge,
    required this.gstPercent,
    required this.incomeTaxPercent,
    required this.electricityDuty,
    required this.tvFee,
    required this.peakRate,
    required this.offPeakRate,
  });
}

// ── Threshold ──────────────────────────────────────────────────────────────

enum ThresholdCondition { greaterThan, lessThan, between, outsideRange }

class ThresholdRule {
  final String id;
  final String homeId;
  final String? meterId;
  final ParameterType parameter;
  final String phaseOrTotal;
  final ThresholdCondition condition;
  final double value;
  final double? value2;
  final int durationMinutes;
  final AlertSeverity severity;
  final bool isActive;
  final bool isTriggered;

  const ThresholdRule({
    required this.id,
    required this.homeId,
    this.meterId,
    required this.parameter,
    required this.phaseOrTotal,
    required this.condition,
    required this.value,
    this.value2,
    required this.durationMinutes,
    required this.severity,
    required this.isActive,
    required this.isTriggered,
  });
}

// ── Alert ──────────────────────────────────────────────────────────────────

class AlertModel {
  final String id;
  final String type;
  final String homeId;
  final String meterId;
  final ParameterType parameter;
  final String phaseOrTotal;
  final double actualValue;
  final double thresholdValue;
  final AlertSeverity severity;
  final AlertStatus status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String description;

  const AlertModel({
    required this.id,
    required this.type,
    required this.homeId,
    required this.meterId,
    required this.parameter,
    required this.phaseOrTotal,
    required this.actualValue,
    required this.thresholdValue,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
    required this.description,
  });
}

// ── Bill Estimate ──────────────────────────────────────────────────────────

class BillEstimate {
  final String homeId;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final double totalUnits;
  final int currentSlab;
  final double currentSlabRate;
  final double avgCostPerUnit;
  final double energyCharges;
  final double fixedCharges;
  final double fpaCharges;
  final double qtaCharges;
  final double fcSurcharge;
  final double taxes;
  final double estimatedTotal;
  final double projectedBill;
  final double budget;
  final String tariffVersionId;

  const BillEstimate({
    required this.homeId,
    required this.cycleStart,
    required this.cycleEnd,
    required this.totalUnits,
    required this.currentSlab,
    required this.currentSlabRate,
    required this.avgCostPerUnit,
    required this.energyCharges,
    required this.fixedCharges,
    required this.fpaCharges,
    required this.qtaCharges,
    required this.fcSurcharge,
    required this.taxes,
    required this.estimatedTotal,
    required this.projectedBill,
    required this.budget,
    required this.tariffVersionId,
  });
}

// ── Parameter Display Metadata ────────────────────────────────────────────

class ParameterInfo {
  final ParameterType type;
  final String name;
  final String unit;
  final String shortUnit;
  final bool isMain;
  final IconData icon;
  final Color color;

  const ParameterInfo({
    required this.type,
    required this.name,
    required this.unit,
    required this.shortUnit,
    required this.isMain,
    required this.icon,
    required this.color,
  });
}

const parameterInfoMap = <ParameterType, ParameterInfo>{
  ParameterType.energyConsumption: ParameterInfo(
    type: ParameterType.energyConsumption,
    name: 'Energy',
    unit: 'kWh',
    shortUnit: 'kWh',
    isMain: true,
    icon: Icons.bolt,
    color: Color(0xFF1D5AFF),
  ),
  ParameterType.voltage: ParameterInfo(
    type: ParameterType.voltage,
    name: 'Voltage',
    unit: 'Volt',
    shortUnit: 'V',
    isMain: true,
    icon: Icons.electric_bolt,
    color: Color(0xFF8B5CF6),
  ),
  ParameterType.current: ParameterInfo(
    type: ParameterType.current,
    name: 'Current',
    unit: 'Ampere',
    shortUnit: 'A',
    isMain: true,
    icon: Icons.electrical_services,
    color: Color(0xFFF59E0B),
  ),
  ParameterType.power: ParameterInfo(
    type: ParameterType.power,
    name: 'Power',
    unit: 'kW',
    shortUnit: 'kW',
    isMain: true,
    icon: Icons.power,
    color: Color(0xFFEF4444),
  ),
  ParameterType.cost: ParameterInfo(
    type: ParameterType.cost,
    name: 'Cost',
    unit: 'PKR',
    shortUnit: '₨',
    isMain: true,
    icon: Icons.payments,
    color: Color(0xFF22C55E),
  ),
  ParameterType.powerFactor: ParameterInfo(
    type: ParameterType.powerFactor,
    name: 'Power Factor',
    unit: 'ratio',
    shortUnit: 'PF',
    isMain: false,
    icon: Icons.speed,
    color: Color(0xFF06B6D4),
  ),
  ParameterType.frequency: ParameterInfo(
    type: ParameterType.frequency,
    name: 'Frequency',
    unit: 'Hz',
    shortUnit: 'Hz',
    isMain: false,
    icon: Icons.waves,
    color: Color(0xFF84CC16),
  ),
  ParameterType.peakDemand: ParameterInfo(
    type: ParameterType.peakDemand,
    name: 'Peak Demand',
    unit: 'kW',
    shortUnit: 'kW',
    isMain: false,
    icon: Icons.trending_up,
    color: Color(0xFFF97316),
  ),
  ParameterType.activePower: ParameterInfo(
    type: ParameterType.activePower,
    name: 'Active Power',
    unit: 'kW',
    shortUnit: 'kW',
    isMain: false,
    icon: Icons.flash_on,
    color: Color(0xFF3B82F6),
  ),
  ParameterType.reactivePower: ParameterInfo(
    type: ParameterType.reactivePower,
    name: 'Reactive Power',
    unit: 'kVAR',
    shortUnit: 'kVAR',
    isMain: false,
    icon: Icons.flash_off,
    color: Color(0xFFEC4899),
  ),
  ParameterType.costPerUnit: ParameterInfo(
    type: ParameterType.costPerUnit,
    name: 'Cost Per Unit',
    unit: 'PKR/unit',
    shortUnit: '₨/u',
    isMain: false,
    icon: Icons.price_change,
    color: Color(0xFF10B981),
  ),
};

extension ParameterTypeExtension on ParameterType {
  ParameterInfo get info => parameterInfoMap[this]!;
}

extension MeterStatusExtension on MeterStatus {
  Color get color {
    switch (this) {
      case MeterStatus.online: return const Color(0xFF22C55E);
      case MeterStatus.delayed: return const Color(0xFFF59E0B);
      case MeterStatus.offline: return const Color(0xFF94A3B8);
      case MeterStatus.warning: return const Color(0xFFF59E0B);
      case MeterStatus.critical: return const Color(0xFFEF4444);
    }
  }

  String get label {
    switch (this) {
      case MeterStatus.online: return 'Online';
      case MeterStatus.delayed: return 'Delayed';
      case MeterStatus.offline: return 'Offline';
      case MeterStatus.warning: return 'Warning';
      case MeterStatus.critical: return 'Critical';
    }
  }
}

extension AlertSeverityExtension on AlertSeverity {
  Color get color {
    switch (this) {
      case AlertSeverity.info: return const Color(0xFF1D5AFF);
      case AlertSeverity.warning: return const Color(0xFFF59E0B);
      case AlertSeverity.critical: return const Color(0xFFEF4444);
    }
  }

  String get label {
    switch (this) {
      case AlertSeverity.info: return 'Info';
      case AlertSeverity.warning: return 'Warning';
      case AlertSeverity.critical: return 'Critical';
    }
  }
}
