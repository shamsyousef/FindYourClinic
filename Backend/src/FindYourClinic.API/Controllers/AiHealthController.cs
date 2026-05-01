using FindYourClinic.API.Common;
using FindYourClinic.API.Features.AiHealth.AnalyzeSymptoms;
using FindYourClinic.API.Features.AiHealth.GetChatHistory;
using FindYourClinic.API.Features.AiHealth.SendMessage;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

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
    public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request, CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User).ToString();
        var result = await _mediator.Send(new SendMessageCommand(userId, request.Content), cancellationToken);
        return Ok(result);
    }

    [HttpGet("chat/history")]
    public async Task<IActionResult> GetChatHistory(CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User).ToString();
        var result = await _mediator.Send(new GetChatHistoryQuery(userId), cancellationToken);
        return Ok(result);
    }

    [HttpPost("symptoms/analyze")]
    public async Task<IActionResult> AnalyzeSymptoms([FromBody] AnalyzeSymptomsCommand command, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(command, cancellationToken);
        return Ok(result);
    }

    public sealed class SendMessageRequest
    {
        public string Content { get; set; } = string.Empty;
    }
}
