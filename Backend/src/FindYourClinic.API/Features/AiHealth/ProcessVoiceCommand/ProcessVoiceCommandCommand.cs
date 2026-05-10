using MediatR;

namespace FindYourClinic.API.Features.AiHealth.ProcessVoiceCommand;

/// <summary>
/// One-shot voice command parsing for the blind-patient assistant.
/// Calls Gemini with a JSON-mode prompt and does NOT persist anything to chat history.
/// </summary>
public record ProcessVoiceCommandCommand(
    string Transcript,
    string? CurrentScreen,
    string? ScreenContextJson
) : IRequest<ProcessVoiceCommandResult>;

/// <summary>
/// Structured intent returned by Gemini.
///
/// Intent is a stable string identifier (lowercase snake_case) such as:
/// "navigate_appointments", "navigate_search", "navigate_home", "navigate_profile",
/// "navigate_nearby_clinics", "navigate_notifications", "navigate_ai_chat",
/// "book_appointment", "read_next_appointment", "read_all_upcoming_appointments",
/// "read_screen", "search_doctor", "select_item", "go_back", "help",
/// "cancel", "unknown".
///
/// Parameters carries intent-specific values, e.g. {"query": "cardiologist"}
/// for search_doctor or {"index": 2} for select_item. Always present (may be empty).
///
/// SpokenResponse is the natural-language sentence the app should read aloud
/// to the blind patient (e.g. "Opening doctor search").
/// </summary>
public record ProcessVoiceCommandResult(
    string Intent,
    Dictionary<string, object?> Parameters,
    string SpokenResponse
);
