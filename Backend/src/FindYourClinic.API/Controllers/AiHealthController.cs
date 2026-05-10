using FindYourClinic.API.Common;
using FindYourClinic.API.Features.AiHealth.AnalyzeSymptoms;
using FindYourClinic.API.Features.AiHealth.GetChatHistory;
using FindYourClinic.API.Features.AiHealth.ProcessVoiceCommand;
using FindYourClinic.API.Features.AiHealth.SendMessage;
using FindYourClinic.Domain.Common;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/ai")]
[Authorize]
public class AiHealthController : ControllerBase
{
    private readonly IMediator _mediator;

    public AiHealthController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost("chat")]
    [EnableRateLimiting("ai_limited")]
    public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request, CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User).ToString();
        var result = await _mediator.Send(new SendMessageCommand(userId, request.Content), cancellationToken);
        return Ok(ApiResponse<SendMessageResult>.Ok(result));
    }

    [HttpGet("chat/history")]
    public async Task<IActionResult> GetChatHistory(CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User).ToString();
        var result = await _mediator.Send(new GetChatHistoryQuery(userId), cancellationToken);
        return Ok(ApiResponse<List<ChatMessageDto>>.Ok(result));
    }

    [HttpPost("symptoms/analyze")]
    [EnableRateLimiting("ai_limited")]
    public async Task<IActionResult> AnalyzeSymptoms([FromBody] AnalyzeSymptomsCommand command, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(command, cancellationToken);
        return Ok(ApiResponse<SymptomAnalysisResult>.Ok(result));
    }

    /// <summary>
    /// One-shot voice-command intent parsing for the blind-patient assistant.
    /// Does NOT store anything in chat history.
    /// </summary>
    [HttpPost("voice-command")]
    [EnableRateLimiting("ai_limited")]
    public async Task<IActionResult> ProcessVoiceCommand(
        [FromBody] VoiceCommandRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new ProcessVoiceCommandCommand(
                request.Transcript,
                request.CurrentScreen,
                request.ScreenContextJson),
            cancellationToken);
        return Ok(ApiResponse<ProcessVoiceCommandResult>.Ok(result));
    }

    public sealed class SendMessageRequest
    {
        public string Content { get; set; } = string.Empty;
    }

    public sealed class VoiceCommandRequest
    {
        public string Transcript { get; set; } = string.Empty;
        public string? CurrentScreen { get; set; }
        public string? ScreenContextJson { get; set; }
    }
}
