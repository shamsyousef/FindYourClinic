using System.Text.Json;
using FindYourClinic.API.Services;
using MediatR;

namespace FindYourClinic.API.Features.AiHealth.AnalyzeSymptoms;

public class AnalyzeSymptomsCommandHandler : IRequestHandler<AnalyzeSymptomsCommand, SymptomAnalysisResult>
{
    private readonly IGeminiService _geminiService;

    public AnalyzeSymptomsCommandHandler(IGeminiService geminiService)
    {
        _geminiService = geminiService;
    }

    public async Task<SymptomAnalysisResult> Handle(AnalyzeSymptomsCommand request, CancellationToken cancellationToken)
    {
        var symptomsText = string.Join(", ", request.Symptoms);
        var prompt = $$"""
            A patient reports the following symptoms: {{symptomsText}}.

            Respond ONLY with valid JSON in this exact format (no markdown, no explanation):
            {
              "condition": "brief condition name",
              "severity": "mild|moderate|severe",
              "recommendations": ["recommendation 1", "recommendation 2", "recommendation 3", "recommendation 4"],
              "specialistType": "General Practitioner|Cardiologist|Neurologist|Gastroenterologist|Pulmonologist|Dermatologist|Orthopedic Surgeon|ENT Specialist"
            }
            """;

        var response = await _geminiService.GenerateResponseAsync(
            new List<(string role, string content)> { ("user", prompt) });

        try
        {
            var cleaned = response.Trim();
            if (cleaned.StartsWith("```"))
            {
                var firstNewline = cleaned.IndexOf('\n');
                var lastFence = cleaned.LastIndexOf("```");
                if (firstNewline >= 0 && lastFence > firstNewline)
                {
                    cleaned = cleaned[(firstNewline + 1)..lastFence].Trim();
                }
            }

            var parsed = JsonSerializer.Deserialize<JsonElement>(cleaned);

            var condition = parsed.GetProperty("condition").GetString() ?? "General Symptoms";
            var severity = parsed.GetProperty("severity").GetString() ?? "mild";
            var specialistType = parsed.GetProperty("specialistType").GetString() ?? "General Practitioner";

            var recommendations = new List<string>();
            foreach (var item in parsed.GetProperty("recommendations").EnumerateArray())
            {
                var rec = item.GetString();
                if (rec is not null)
                    recommendations.Add(rec);
            }

            return new SymptomAnalysisResult(condition, severity, recommendations, specialistType);
        }
        catch
        {
            return new SymptomAnalysisResult(
                "General Symptoms",
                "mild",
                ["Monitor your symptoms", "Stay hydrated", "Rest", "Consult a doctor if symptoms persist"],
                "General Practitioner");
        }
    }
}
