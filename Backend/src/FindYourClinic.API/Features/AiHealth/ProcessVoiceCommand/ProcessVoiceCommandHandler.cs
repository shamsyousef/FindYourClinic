using System.Text.Json;
using FindYourClinic.API.Services;
using MediatR;

namespace FindYourClinic.API.Features.AiHealth.ProcessVoiceCommand;

public class ProcessVoiceCommandHandler
    : IRequestHandler<ProcessVoiceCommandCommand, ProcessVoiceCommandResult>
{
    private const string SystemPrompt = """
        You are a voice-command interpreter for a blind patient using a healthcare app called "Find Your Clinic".
        Your job is to map the patient's spoken transcript into ONE structured intent.

        Allowed intents (use the exact id):
        - navigate_home               → Open the home dashboard
        - navigate_appointments       → Open the patient's appointments list
        - navigate_search             → Open doctor search (optional parameters: {"query": "<specialty or doctor name>"})
        - navigate_nearby_clinics     → Open the nearby clinics map
        - navigate_profile            → Open the patient's profile
        - navigate_ai_chat            → Open the AI health assistant chat
        - navigate_notifications      → Open the notifications list
        - navigate_health_records     → Open the health records screen
        - navigate_conversations      → Open the patient's messages and chats with doctors
        - navigate_edit_profile       → Open the screen to edit the patient's profile
        - book_appointment            → Book a new appointment. When the current screen is "doctor_profile" the app books the doctor's next available slot directly as a cash-in-clinic appointment — return book_appointment with a brief confirmation like "Booking the next available slot.". Phrases that map here include "book", "book appointment", "book this doctor", "book in cash", "make a cash appointment", "schedule appointment". (parameters: {"doctorName": "<optional>", "specialty": "<optional>"})
        - read_next_appointment       → Speak the patient's next upcoming appointment time aloud
        - read_all_upcoming_appointments → Speak all upcoming appointments aloud
        - read_screen                 → Speak a summary of what is currently on the screen
        - select_item                 → Select an item from a list by ordinal (parameters: {"index": <1-based integer>})
        - go_back                     → Navigate back / pop the current screen
        - help                        → Speak the list of supported commands
        - cancel                      → Cancel / stop the current voice interaction
        - confirm                     → Confirm an action (e.g. "yes", "confirm", "نعم", "تأكيد")
        - deny                        → Deny an action (e.g. "no", "deny", "لا", "رفض")
        - unknown                     → The transcript does not map to any supported intent

        Rules:
        1. Respond ONLY with valid JSON. No markdown fences. No explanation outside the JSON.
        2. The JSON shape MUST be exactly:
           {
             "intent": "<one of the ids above>",
             "parameters": { ... },
             "spokenResponse": "<short natural sentence to speak to the user>"
           }
        3. spokenResponse must be a single short sentence (max 25 words) suitable for text-to-speech.
        4. CRITICAL: Detect the language of the transcript. Your spokenResponse MUST be in the EXACT SAME LANGUAGE as the transcript (either Arabic or English).
        5. parameters must always be a JSON object (use {} when there are no parameters).
        6. If the transcript is empty, gibberish, or unrelated, return intent="unknown" with an apologetic spokenResponse in the appropriate language that suggests saying "help".
        7. The patient is BLIND — be warm and clear. Confirm the action you understood.
        8. If a screen context is provided and the user says "read this screen" or similar, return read_screen.
        9. For search_doctor or book_appointment, if the user mentions a specialty (cardiologist, طبيب قلب, etc.) or doctor name, put it in parameters.
        """;

    private readonly IGeminiService _geminiService;
    private readonly ILogger<ProcessVoiceCommandHandler> _logger;

    public ProcessVoiceCommandHandler(IGeminiService geminiService, ILogger<ProcessVoiceCommandHandler> logger)
    {
        _geminiService = geminiService;
        _logger = logger;
    }

    public async Task<ProcessVoiceCommandResult> Handle(
        ProcessVoiceCommandCommand request,
        CancellationToken cancellationToken)
    {
        var transcript = (request.Transcript ?? string.Empty).Trim();
        if (transcript.Length == 0)
        {
            return new ProcessVoiceCommandResult(
                "unknown",
                new Dictionary<string, object?>(),
                "I didn't hear anything. Please tap and try again.");
        }

        var contextLine = string.IsNullOrWhiteSpace(request.CurrentScreen)
            ? string.Empty
            : $"Current screen: {request.CurrentScreen}.\n";

        var screenContext = string.IsNullOrWhiteSpace(request.ScreenContextJson)
            ? string.Empty
            : $"Screen context (JSON): {request.ScreenContextJson}\n";

        var userPrompt = $"""
            {contextLine}{screenContext}Patient transcript: "{transcript}"

            Return the JSON now.
            """;

        try
        {
            var response = await _geminiService.GenerateResponseAsync(
                new List<(string role, string content)> { ("user", userPrompt) },
                SystemPrompt);

            return ParseGeminiJson(response);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Voice command Gemini call failed for transcript '{Transcript}'", transcript);
            return new ProcessVoiceCommandResult(
                "unknown",
                new Dictionary<string, object?>(),
                "Sorry, I couldn't understand that right now. Please try again.");
        }
    }

    private static ProcessVoiceCommandResult ParseGeminiJson(string raw)
    {
        var cleaned = raw.Trim();
        if (cleaned.StartsWith("```"))
        {
            var firstNewline = cleaned.IndexOf('\n');
            var lastFence = cleaned.LastIndexOf("```");
            if (firstNewline >= 0 && lastFence > firstNewline)
            {
                cleaned = cleaned[(firstNewline + 1)..lastFence].Trim();
            }
        }

        try
        {
            var parsed = JsonSerializer.Deserialize<JsonElement>(cleaned);

            var intent = parsed.TryGetProperty("intent", out var intentEl) && intentEl.ValueKind == JsonValueKind.String
                ? (intentEl.GetString() ?? "unknown")
                : "unknown";

            var spoken = parsed.TryGetProperty("spokenResponse", out var spokenEl) && spokenEl.ValueKind == JsonValueKind.String
                ? (spokenEl.GetString() ?? string.Empty)
                : string.Empty;

            var parameters = new Dictionary<string, object?>();
            if (parsed.TryGetProperty("parameters", out var paramsEl) && paramsEl.ValueKind == JsonValueKind.Object)
            {
                foreach (var prop in paramsEl.EnumerateObject())
                {
                    parameters[prop.Name] = ExtractJsonValue(prop.Value);
                }
            }

            if (string.IsNullOrWhiteSpace(spoken))
            {
                spoken = intent == "unknown"
                    ? "Sorry, I didn't understand. Say 'help' to hear what I can do."
                    : "Done.";
            }

            return new ProcessVoiceCommandResult(intent, parameters, spoken);
        }
        catch
        {
            return new ProcessVoiceCommandResult(
                "unknown",
                new Dictionary<string, object?>(),
                "Sorry, I couldn't understand that. Say 'help' to hear what I can do.");
        }
    }

    private static object? ExtractJsonValue(JsonElement el) => el.ValueKind switch
    {
        JsonValueKind.String => el.GetString(),
        JsonValueKind.Number => el.TryGetInt64(out var l) ? l : el.GetDouble(),
        JsonValueKind.True => true,
        JsonValueKind.False => false,
        JsonValueKind.Null => null,
        _ => el.GetRawText(),
    };
}
