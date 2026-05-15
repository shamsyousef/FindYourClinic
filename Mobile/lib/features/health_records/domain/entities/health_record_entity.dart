enum HealthRecordType {
  bloodPressure, // 0
  heartRate, // 1
  labResult, // 2
  prescription, // 3
  other, // 4
  bloodTest, // 5
  radiology, // 6
  vaccination, // 7
  bloodSugar, // 8
  temperature, // 9
  weight, // 10
  spO2, // 11
  allergy, // 12
}

class VitalEntity {
  final String value;
  final String? unit;
  final DateTime recordedAt;

  const VitalEntity({
    required this.value,
    this.unit,
    required this.recordedAt,
  });
}

class HealthSummaryEntity {
  final int totalRecords;
  final VitalEntity? bloodPressure;
  final VitalEntity? heartRate;
  final VitalEntity? bloodSugar;
  final VitalEntity? temperature;
  final VitalEntity? weight;
  final VitalEntity? spO2;

  const HealthSummaryEntity({
    required this.totalRecords,
    this.bloodPressure,
    this.heartRate,
    this.bloodSugar,
    this.temperature,
    this.weight,
    this.spO2,
  });

  List<MapEntry<String, VitalEntity>> get activeVitals => [
    if (bloodPressure != null) MapEntry('Blood Pressure', bloodPressure!),
    if (heartRate != null) MapEntry('Heart Rate', heartRate!),
    if (bloodSugar != null) MapEntry('Blood Sugar', bloodSugar!),
    if (temperature != null) MapEntry('Temperature', temperature!),
    if (weight != null) MapEntry('Weight', weight!),
    if (spO2 != null) MapEntry('SpO2', spO2!),
  ];
}

class HealthRecordEntity {
  final String id;
  final String title;
  final HealthRecordType type;
  final String? value;
  final String? unit;
  final DateTime recordedAt;
  final String? notes;
  final String? fileUrl;

  const HealthRecordEntity({
    required this.id,
    required this.title,
    required this.type,
    this.value,
    this.unit,
    required this.recordedAt,
    this.notes,
    this.fileUrl,
  });
}
