using FindYourClinic.API.Common;
using FindYourClinic.API.Features.HealthRecords.CreateHealthRecord;
using FindYourClinic.API.Features.HealthRecords.DeleteHealthRecord;
using FindYourClinic.API.Features.HealthRecords.GetHealthRecordById;
using FindYourClinic.API.Features.HealthRecords.GetHealthRecordStats;
using FindYourClinic.API.Features.HealthRecords.GetHealthSummary;
using FindYourClinic.API.Features.HealthRecords.GetMyRecords;
using FindYourClinic.API.Features.HealthRecords.GetPatientRecords;
using FindYourClinic.API.Features.HealthRecords.UpdateHealthRecord;
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

    /// <summary>Get my health records (patient only). Optional type filter.</summary>
    [HttpGet]
    public async Task<IActionResult> GetMyRecords([FromQuery] HealthRecordType? type, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetMyHealthRecordsQuery
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User),
            Type = type
        }, cancellationToken);
        return Ok(result);
    }

    /// <summary>Create a new health record (patient only).</summary>
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
            Unit = request.Unit,
            RecordedAt = request.RecordedAt,
            Notes = request.Notes
        }, cancellationToken);
        return Ok(result);
    }

    /// <summary>Update an existing health record (patient only).</summary>
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update([FromRoute] Guid id, [FromBody] UpdateHealthRecordRequest request, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new UpdateHealthRecordCommand
        {
            RecordId = id,
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User),
            Title = request.Title,
            Type = request.Type,
            Value = request.Value,
            Unit = request.Unit,
            RecordedAt = request.RecordedAt,
            Notes = request.Notes
        }, cancellationToken);
        return Ok(result);
    }

    /// <summary>Get a single health record by ID (patient only).</summary>
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

    /// <summary>Delete a health record (patient only).</summary>
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

    /// <summary>Get vitals summary (patient only).</summary>
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

    /// <summary>Doctor: view a patient's health records (requires appointment relationship).</summary>
    [HttpGet("patient/{patientId:guid}")]
    public async Task<IActionResult> GetPatientRecords(
        [FromRoute] Guid patientId,
        [FromQuery] HealthRecordType? type,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetPatientRecordsQuery
        {
            DoctorUserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User),
            PatientId = patientId,
            Type = type
        }, cancellationToken);
        return Ok(result);
    }

    /// <summary>Admin: aggregate health record statistics.</summary>
    [HttpGet("admin/stats")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdminStats(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetHealthRecordStatsQuery(), cancellationToken);
        return Ok(result);
    }

    // ─── Request DTOs ───

    public sealed class CreateHealthRecordRequest
    {
        public string Title { get; set; } = string.Empty;
        public HealthRecordType Type { get; set; }
        public string? Value { get; set; }
        public string? Unit { get; set; }
        public DateTime? RecordedAt { get; set; }
        public string? Notes { get; set; }
    }

    public sealed class UpdateHealthRecordRequest
    {
        public string Title { get; set; } = string.Empty;
        public HealthRecordType Type { get; set; }
        public string? Value { get; set; }
        public string? Unit { get; set; }
        public DateTime? RecordedAt { get; set; }
        public string? Notes { get; set; }
    }
}
