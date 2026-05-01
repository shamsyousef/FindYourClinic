import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/health_record_entity.dart';

class VitalModel {
  final String value;
  final String? unit;
  final DateTime recordedAt;

  const VitalModel({
    required this.value,
    this.unit,
    required this.recordedAt,
  });

  factory VitalModel.fromJson(Map<String, dynamic> json) => VitalModel(
        value: json['value'] as String,
        unit: json['unit'] as String?,
        recordedAt: parseServerDateTime(json['recordedAt'] as String),
      );

  VitalEntity toEntity() => VitalEntity(
        value: value,
        unit: unit,
        recordedAt: recordedAt,
      );
}

class HealthSummaryModel {
  final int totalRecords;
  final VitalModel? bloodPressure;
  final VitalModel? heartRate;
  final VitalModel? bloodSugar;
  final VitalModel? temperature;
  final VitalModel? weight;
  final VitalModel? spO2;

  const HealthSummaryModel({
    required this.totalRecords,
    this.bloodPressure,
    this.heartRate,
    this.bloodSugar,
    this.temperature,
    this.weight,
    this.spO2,
  });

  factory HealthSummaryModel.fromJson(Map<String, dynamic> json) {
    VitalModel? parseVital(String key) {
      final v = json[key] as Map<String, dynamic>?;
      return v != null ? VitalModel.fromJson(v) : null;
    }

    return HealthSummaryModel(
      totalRecords: json['totalRecords'] as int? ?? 0,
      bloodPressure: parseVital('bloodPressure'),
      heartRate: parseVital('heartRate'),
      bloodSugar: parseVital('bloodSugar'),
      temperature: parseVital('temperature'),
      weight: parseVital('weight'),
      spO2: parseVital('spO2'),
    );
  }

  HealthSummaryEntity toEntity() => HealthSummaryEntity(
        totalRecords: totalRecords,
        bloodPressure: bloodPressure?.toEntity(),
        heartRate: heartRate?.toEntity(),
        bloodSugar: bloodSugar?.toEntity(),
        temperature: temperature?.toEntity(),
        weight: weight?.toEntity(),
        spO2: spO2?.toEntity(),
      );
}
