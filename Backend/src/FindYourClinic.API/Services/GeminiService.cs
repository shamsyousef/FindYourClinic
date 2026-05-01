using System.Net.Http.Json;
using System.Text;
using System.Text.Json;

namespace FindYourClinic.API.Services;

public class GeminiService : IGeminiService
{
    private const string MedicalSystemPrompt =
        "You are a medical health assistant. Only answer questions related to health, medicine, symptoms, medications, and wellness. " +
        "If asked about non-medical topics, politely redirect to health topics. " +
        "Always include: \"This is general information only — consult a doctor for medical advice.\" " +
        "Keep answers concise and clear.";

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;

    public GeminiService(IHttpClientFactory httpClientFactory, IConfiguration configuration)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
    }

    public async Task<string> GenerateResponseAsync(List<(string role, string content)> conversationHistory, string? systemPrompt = null)
    {
        var apiKey = _configuration["Gemini:ApiKey"]
            ?? throw new InvalidOperationException("Gemini:ApiKey is not configured.");
        var model = _configuration["Gemini:Model"] ?? "gemini-2.5-pro";

        var url = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}";

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

        var client = _httpClientFactory.CreateClient();
        var json = JsonSerializer.Serialize(requestBody);
        using var httpContent = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await client.PostAsync(url, httpContent);

        if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
            throw new InvalidOperationException("AI service is temporarily busy. Please wait a moment and try again.");

        response.EnsureSuccessStatusCode();

        using var responseStream = await response.Content.ReadAsStreamAsync();
        using var document = await JsonDocument.ParseAsync(responseStream);

        var text = document
            .RootElement
            .GetProperty("candidates")[0]
            .GetProperty("content")
            .GetProperty("parts")[0]
            .GetProperty("text")
            .GetString();

        return text ?? string.Empty;
    }
}
