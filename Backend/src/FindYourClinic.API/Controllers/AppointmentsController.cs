using FindYourClinic.API.Common;
using FindYourClinic.API.Features.Appointments.BookAppointment;
using FindYourClinic.API.Features.Appointments.CancelAppointment;
using FindYourClinic.API.Features.Appointments.CompleteAppointment;
using FindYourClinic.API.Features.Appointments.ConfirmAppointment;
using FindYourClinic.API.Features.Appointments.GetAppointmentById;
using FindYourClinic.API.Features.Appointments.GetDoctorAppointments;
using FindYourClinic.API.Features.Appointments.GetMyAppointments;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/appointments")]
[Authorize]
public class AppointmentsController : ControllerBase
{
    private readonly IMediator _mediator;

    public AppointmentsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost]
    public async Task<IActionResult> Book([FromBody] BookAppointmentRequest request, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new BookAppointmentCommand
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User),
            DoctorProfileId = request.DoctorProfileId,
            ScheduledAt = request.ScheduledAt,
            LocationName = request.LocationName
        }, cancellationToken);
        return Ok(result);
    }

    [HttpGet("my")]
    public async Task<IActionResult> GetMyAppointments(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetMyAppointmentsQuery
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById([FromRoute] Guid id, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetAppointmentByIdQuery
        {
            AppointmentId = id,
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    [HttpGet("doctor/my")]
    public async Task<IActionResult> GetDoctorAppointments(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetDoctorAppointmentsQuery
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    [HttpPut("{id:guid}/cancel")]
    public async Task<IActionResult> Cancel([FromRoute] Guid id, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new CancelAppointmentCommand
        {
            AppointmentId = id,
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    [HttpPut("{id:guid}/confirm")]
    public async Task<IActionResult> Confirm([FromRoute] Guid id, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new ConfirmAppointmentCommand
        {
            AppointmentId = id,
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    [HttpPut("{id:guid}/complete")]
    public async Task<IActionResult> Complete([FromRoute] Guid id, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new CompleteAppointmentCommand
        {
            AppointmentId = id,
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    public sealed class BookAppointmentRequest
    {
        public Guid DoctorProfileId { get; set; }
        public DateTime ScheduledAt { get; set; }
        public string? LocationName { get; set; }
    }
}
