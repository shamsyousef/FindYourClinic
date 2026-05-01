using MediatR;

namespace FindYourClinic.API.Features.AiHealth.AnalyzeSymptoms;

public record AnalyzeSymptomsCommand(List<string> Symptoms) : IRequest<SymptomAnalysisResult>;
public record SymptomAnalysisResult(string Condition, string Severity, List<string> Recommendations, string SpecialistType);
