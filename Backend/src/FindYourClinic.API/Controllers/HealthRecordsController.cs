using FindYourClinic.API.Common;
using FindYourClinic.API.Features.HealthRecords.CreateHealthRecord;
using FindYourClinic.API.Features.HealthRecords.DeleteHealthRecord;
using FindYourClinic.API.Features.HealthRecords.GetHealthRecordById;
using FindYourClinic.API.Features.HealthRecords.GetHealthSummary;
using FindYourClinic.API.Features.HealthRecords.GetMyRecords;
using FindYourClinic.Domain.Enums;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/health-records")]
[Authorize]
public class HealthRecordsController : ControllerBase
{
    private readonly IMediator _mediator;

    public HealthRecordsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet]
    public async Task<IActionResult> GetMyRecords(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetMyHealthRecordsQuery
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> Add([FromBody] CreateHealthRecordRequest request, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new CreateHealthRecordCommand
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User),
            Title = request.Title,
            Type = request.Type,
            Value = request.Value,
            RecordedAt = request.RecordedAt,
            Notes = request.Notes
        }, cancellationToken);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetOne([FromRoute] Guid id, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetHealthRecordByIdQuery
        {
            RecordId = id,
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete([FromRoute] Guid id, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new DeleteHealthRecordCommand
        {
            RecordId = id,
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetHealthSummaryQuery
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    public sealed class CreateHealthRecordRequest
    {
        public string Title { get; set; } = string.Empty;
        public HealthRecordType Type { get; set; }
        public string? Value { get; set; }
        public DateTime? RecordedAt { get; set; }
        public string? Notes { get; set; }
    }
}
