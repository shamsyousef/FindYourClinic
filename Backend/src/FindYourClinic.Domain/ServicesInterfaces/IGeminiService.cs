namespace FindYourClinic.API.Services;

public interface IGeminiService
{
    Task<string> GenerateResponseAsync(List<(string role, string content)> conversationHistory, string? systemPrompt = null, string language = "en");
}
