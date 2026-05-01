import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/health_record_entity.dart';

class HealthRecordModel {
  final String id;
  final String title;
  final String type;
  final String? value;
  final String? unit;
  final DateTime recordedAt;
  final String? notes;
  final String? fileUrl;

  const HealthRecordModel({
    required this.id,
    required this.title,
    required this.type,
    this.value,
    this.unit,
    required this.recordedAt,
    this.notes,
    this.fileUrl,
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) =>
      HealthRecordModel(
        id: json['id'] as String,
        title: json['title'] as String,
        type: json['type'] as String? ?? 'Other',
        value: json['value'] as String?,
        unit: json['unit'] as String?,
        recordedAt: parseServerDateTime(json['recordedAt'] as String),
        notes: json['notes'] as String?,
        fileUrl: json['fileUrl'] as String?,
      );

  HealthRecordEntity toEntity() => HealthRecordEntity(
        id: id,
        title: title,
        type: _parseType(type),
        value: value,
        unit: unit,
        recordedAt: recordedAt,
        notes: notes,
        fileUrl: fileUrl,
      );

  static HealthRecordType _parseType(String type) =>
      switch (type.toLowerCase()) {
        'bloodpressure' => HealthRecordType.bloodPressure,
        'heartrate' => HealthRecordType.heartRate,
        'labresult' => HealthRecordType.labResult,
        'prescription' => HealthRecordType.prescription,
        'bloodtest' => HealthRecordType.bloodTest,
        'radiology' => HealthRecordType.radiology,
        'vaccination' => HealthRecordType.vaccination,
        'bloodsugar' => HealthRecordType.bloodSugar,
        'temperature' => HealthRecordType.temperature,
        'weight' => HealthRecordType.weight,
        'spo2' => HealthRecordType.spO2,
        _ => HealthRecordType.other,
      };
}
