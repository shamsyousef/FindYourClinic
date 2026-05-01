// Domain entity for symptom analysis results.
// Pure Dart — no Flutter imports.

class SymptomAnalysis {
  final String condition;
  final String severity; // "mild", "moderate", or "severe"
  final List<String> recommendations;
  final String specialistType;

  const SymptomAnalysis({
    required this.condition,
    required this.severity,
    required this.recommendations,
    required this.specialistType,
  });
}
