using System.Text.Json;
using FindYourClinic.API.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.AiHealth.AnalyzeSymptoms;

public class AnalyzeSymptomsCommandHandler : IRequestHandler<AnalyzeSymptomsCommand, SymptomAnalysisResult>
{
    private const string FallbackSpecialty = "General Practitioner";

    private readonly IGeminiService _geminiService;
    private readonly ApplicationDbContext _dbContext;

    public AnalyzeSymptomsCommandHandler(IGeminiService geminiService, ApplicationDbContext dbContext)
    {
        _geminiService = geminiService;
        _dbContext = dbContext;
    }

    public async Task<SymptomAnalysisResult> Handle(AnalyzeSymptomsCommand request, CancellationToken cancellationToken)
    {
        var availableSpecialties = await _dbContext.Specialties
            .AsNoTracking()
            .Where(s => s.IsActive)
            .OrderBy(s => s.Name)
            .Select(s => s.Name)
            .ToListAsync(cancellationToken);

        var defaultSpecialty = availableSpecialties.Count == 0
            ? FallbackSpecialty
            : (availableSpecialties.FirstOrDefault(n => string.Equals(n, FallbackSpecialty, StringComparison.OrdinalIgnoreCase))
               ?? availableSpecialties[0]);

        var specialtyOptions = availableSpecialties.Count == 0
            ? FallbackSpecialty
            : string.Join("|", availableSpecialties);

        var symptomsText = string.Join(", ", request.Symptoms);
        var prompt = $$"""
            A patient reports the following symptoms: {{symptomsText}}.

            Pick the "specialistType" value EXACTLY (case and spelling) from this allowed list — no other values are acceptable:
            {{specialtyOptions}}

            Respond ONLY with valid JSON in this exact format (no markdown, no explanation).
            IMPORTANT: Keep the JSON keys exactly as shown (in English). Translate the values of "condition" and "recommendations" to the language requested by the system prompt (e.g., Arabic if requested). The "severity" value MUST be exactly one of: "mild", "moderate", "severe" (do not translate "severity" values).
            {
              "condition": "brief condition name",
              "severity": "mild|moderate|severe",
              "recommendations": ["recommendation 1", "recommendation 2", "recommendation 3", "recommendation 4"],
              "specialistType": "<one of the allowed specialty names>"
            }
            """;

        var response = await _geminiService.GenerateResponseAsync(
            new List<(string role, string content)> { ("user", prompt) }, language: request.Language);

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
            var rawSpecialist = parsed.GetProperty("specialistType").GetString();
            var specialistType = ResolveSpecialty(rawSpecialist, availableSpecialties, defaultSpecialty);

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
                defaultSpecialty);
        }
    }

    private static string ResolveSpecialty(string? aiValue, IReadOnlyList<string> available, string fallback)
    {
        if (string.IsNullOrWhiteSpace(aiValue) || available.Count == 0)
            return fallback;

        var trimmed = aiValue.Trim();

        var exact = available.FirstOrDefault(n => string.Equals(n, trimmed, StringComparison.OrdinalIgnoreCase));
        if (exact is not null) return exact;

        var partial = available.FirstOrDefault(n =>
            n.Contains(trimmed, StringComparison.OrdinalIgnoreCase) ||
            trimmed.Contains(n, StringComparison.OrdinalIgnoreCase));
        return partial ?? fallback;
    }
}