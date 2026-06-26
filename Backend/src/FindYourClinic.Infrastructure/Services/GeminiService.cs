using System.Net;
using System.Text;
using System.Text.Json;
using FindYourClinic.Domain.Exceptions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.API.Services;

public class GeminiService : IGeminiService
{
    private const int MaxRetries = 3;
    private static readonly TimeSpan[] RetryDelays =
    [
        TimeSpan.FromSeconds(2),
        TimeSpan.FromSeconds(4),
        TimeSpan.FromSeconds(8)
    ];

    private const string MedicalSystemPrompt =
        "You are a compassionate health assistant called Find Your Clinic AI. " +
        "Always respond in very short, clear, and direct language so the user doesn't get bored. " +
        "Give small, bite-sized answers. Avoid long paragraphs. " +
        "Never use medical jargon without explaining it in plain words immediately after. " +
        "Always end your response with a clear, reassuring next step the user can take. " +
        "If symptoms sound serious, suggest they seek care calmly. " +
        "Never say 'Diagnosis:' — instead say 'Based on what you shared, this might be...' " +
        "Only answer questions related to health, symptoms, medications, and wellness. " +
        "If relevant, end with a recommended specialist type. " +
        "Keep responses extremely brief (under 50-75 words) unless the user asks for more detail. " +
        "Always end with: 'Remember, I'm here to guide you — not replace your doctor.'";

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<GeminiService> _logger;

    public GeminiService(IHttpClientFactory httpClientFactory, IConfiguration configuration, ILogger<GeminiService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<string> GenerateResponseAsync(List<(string role, string content)> conversationHistory, string? systemPrompt = null)
    {
        var apiKey = _configuration["Gemini:ApiKey"]
            ?? throw new InvalidOperationException("Gemini:ApiKey is not configured.");

        var primaryModel = _configuration["Gemini:Model"] ?? "gemini-2.0-flash";
        var fallbackModels = _configuration.GetSection("Gemini:FallbackModels").Get<string[]>() ?? Array.Empty<string>();

        var models = new List<string> { primaryModel };
        models.AddRange(fallbackModels.Where(m => !string.IsNullOrWhiteSpace(m) && m != primaryModel));

        var effectiveSystemPrompt = string.IsNullOrWhiteSpace(systemPrompt) ? MedicalSystemPrompt : systemPrompt;

        var contents = conversationHistory.Select(turn => new
        {
            role = turn.role == "assistant" ? "model" : turn.role,
            parts = new[] { new { text = turn.content } }
        }).ToList();

        var requestBody = new
        {
            system_instruction = new
            {
                parts = new[] { new { text = effectiveSystemPrompt } }
            },
            contents
        };

        var json = JsonSerializer.Serialize(requestBody);

        for (var modelIndex = 0; modelIndex < models.Count; modelIndex++)
        {
            var model = models[modelIndex];
            var isLastModel = modelIndex == models.Count - 1;

            var (text, outcome) = await TryGenerateWithModelAsync(model, apiKey, json);

            if (outcome == AttemptOutcome.Success)
            {
                if (modelIndex > 0)
                {
                    _logger.LogInformation("Gemini fallback model '{Model}' succeeded after primary failure.", model);
                }
                return text ?? string.Empty;
            }

            if (outcome == AttemptOutcome.QuotaExhausted || outcome == AttemptOutcome.RateLimited)
            {
                if (!isLastModel)
                {
                    _logger.LogWarning("Gemini model '{Model}' exhausted ({Outcome}). Falling back to next model.", model, outcome);
                    continue;
                }

                _logger.LogError("Gemini quota exhausted for all models ({Count} attempted).", models.Count);
                throw new ServiceUnavailableException("AI service is temporarily busy. Please try again in a few minutes.");
            }

            // Hard error (non-429): no point trying fallbacks for the same payload.
            throw new ServiceUnavailableException("AI service encountered an error. Please try again later.");
        }

        throw new ServiceUnavailableException("AI service is unavailable. Please try again later.");
    }

    private async Task<(string? text, AttemptOutcome outcome)> TryGenerateWithModelAsync(string model, string apiKey, string json)
    {
        var url = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}";

        for (var attempt = 0; attempt <= MaxRetries; attempt++)
        {
            var client = _httpClientFactory.CreateClient();
            using var httpContent = new StringContent(json, Encoding.UTF8, "application/json");
            var response = await client.PostAsync(url, httpContent);

            if (response.StatusCode == HttpStatusCode.TooManyRequests)
            {
                var body = await response.Content.ReadAsStringAsync();
                var isQuotaExhausted = IsDailyQuotaExhausted(body);

                if (isQuotaExhausted)
                {
                    _logger.LogWarning("Gemini model '{Model}' daily quota exhausted; skipping retries.", model);
                    return (null, AttemptOutcome.QuotaExhausted);
                }

                if (attempt < MaxRetries)
                {
                    var delay = GetRetryDelay(response, attempt);
                    _logger.LogWarning("Gemini model '{Model}' rate limited (429). Retry {Attempt}/{MaxRetries} after {Delay}s",
                        model, attempt + 1, MaxRetries, delay.TotalSeconds);
                    await Task.Delay(delay);
                    continue;
                }

                _logger.LogWarning("Gemini model '{Model}' rate limited after {MaxRetries} retries.", model, MaxRetries);
                return (null, AttemptOutcome.RateLimited);
            }

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                _logger.LogError("Gemini API error {StatusCode} on model '{Model}': {Body}", (int)response.StatusCode, model, errorBody);
                return (null, AttemptOutcome.Error);
            }

            using var responseStream = await response.Content.ReadAsStreamAsync();
            using var document = await JsonDocument.ParseAsync(responseStream);

            var text = document
                .RootElement
                .GetProperty("candidates")[0]
                .GetProperty("content")
                .GetProperty("parts")[0]
                .GetProperty("text")
                .GetString();

            return (text, AttemptOutcome.Success);
        }

        return (null, AttemptOutcome.RateLimited);
    }

    private static TimeSpan GetRetryDelay(HttpResponseMessage response, int attempt)
    {
        if (response.Headers.RetryAfter?.Delta is { } delta && delta > TimeSpan.Zero)
        {
            return delta;
        }
        return RetryDelays[attempt];
    }

    private static bool IsDailyQuotaExhausted(string body)
    {
        if (string.IsNullOrWhiteSpace(body)) return false;
        try
        {
            using var doc = JsonDocument.Parse(body);
            if (!doc.RootElement.TryGetProperty("error", out var error)) return false;
            if (!error.TryGetProperty("details", out var details)) return false;
            foreach (var detail in details.EnumerateArray())
            {
                if (!detail.TryGetProperty("violations", out var violations)) continue;
                foreach (var v in violations.EnumerateArray())
                {
                    if (v.TryGetProperty("quotaId", out var quotaId) &&
                        quotaId.GetString() is { } id &&
                        id.Contains("PerDay", StringComparison.OrdinalIgnoreCase))
                    {
                        return true;
                    }
                }
            }
        }
        catch (JsonException)
        {
            // If we can't parse, treat as transient and let retries handle it.
        }
        return false;
    }

    private enum AttemptOutcome
    {
        Success,
        RateLimited,
        QuotaExhausted,
        Error
    }
}