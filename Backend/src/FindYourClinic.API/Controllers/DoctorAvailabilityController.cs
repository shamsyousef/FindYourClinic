using FindYourClinic.API.Common;
using FindYourClinic.API.Features.DoctorAvailability.CreateAvailability;
using FindYourClinic.API.Features.DoctorAvailability.GetSlots;
using FindYourClinic.API.Features.DoctorAvailability.Shared;
using FindYourClinic.API.Features.DoctorAvailability.UpdateAvailability;
using FindYourClinic.Domain.Enums;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/doctors/availability")]
public class DoctorAvailabilityController : ControllerBase
{
    private readonly IMediator _mediator;

    public DoctorAvailabilityController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("{doctorId:guid}/slots")]
    [AllowAnonymous]
    public async Task<IActionResult> GetSlots([FromRoute] Guid doctorId, [FromQuery] DateOnly date, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetDoctorAvailabilitySlotsQuery
        {
            DoctorId = doctorId,
            Date = date
        }, cancellationToken);
        return Ok(result);
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] UpsertAvailabilityRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateAvailabilityCommand
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User),
            DayOfWeek = request.DayOfWeek,
            StartTime = request.StartTime,
            EndTime = request.EndTime,
            IsActive = request.IsActive
        };

        var result = await _mediator.Send(command, cancellationToken);
        return Ok(result);
    }

    [HttpPut("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> Update([FromRoute] Guid id, [FromBody] UpsertAvailabilityRequest request, CancellationToken cancellationToken)
    {
        var command = new UpdateAvailabilityCommand
        {
            AvailabilityId = id,
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User),
            DayOfWeek = request.DayOfWeek,
            StartTime = request.StartTime,
            EndTime = request.EndTime,
            IsActive = request.IsActive
        };
        var result = await _mediator.Send(command, cancellationToken);
        return Ok(result);
    }

    public sealed class UpsertAvailabilityRequest
    {
        public DayOfWeek DayOfWeek { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
