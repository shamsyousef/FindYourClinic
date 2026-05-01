import '../../domain/entities/symptom_analysis.dart';

class SymptomAnalysisModel {
  final String condition;
  final String severity;
  final List<String> recommendations;
  final String specialistType;

  const SymptomAnalysisModel({
    required this.condition,
    required this.severity,
    required this.recommendations,
    required this.specialistType,
  });

  factory SymptomAnalysisModel.fromJson(Map<String, dynamic> json) {
    return SymptomAnalysisModel(
      condition: json['condition'] as String,
      severity: json['severity'] as String,
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      specialistType: json['specialistType'] as String,
    );
  }

  SymptomAnalysis toEntity() => SymptomAnalysis(
        condition: condition,
        severity: severity,
        recommendations: recommendations,
        specialistType: specialistType,
      );
}
