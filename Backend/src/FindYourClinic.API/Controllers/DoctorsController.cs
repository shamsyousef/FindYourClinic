using FindYourClinic.API.Common;
using FindYourClinic.API.Features.Doctors.GetDoctorAvailability;
using FindYourClinic.API.Features.Doctors.GetDoctorById;
using FindYourClinic.API.Features.Doctors.GetDoctorDashboard;
using FindYourClinic.API.Features.Doctors.GetDoctorWeeklySchedule;
using FindYourClinic.API.Features.Doctors.GetMyDocuments;
using FindYourClinic.API.Features.Doctors.GetMyStatus;
using FindYourClinic.API.Features.Doctors.GetPaymentInfo;
using FindYourClinic.API.Features.Doctors.GetTopRatedDoctors;
using FindYourClinic.API.Features.Doctors.SavePaymentInfo;
using FindYourClinic.API.Features.Doctors.SearchDoctors;
using FindYourClinic.API.Features.Doctors.UpdateOwnDoctorProfile;
using FindYourClinic.Domain.Enums;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/doctors")]
public class DoctorsController : ControllerBase
{
    private readonly IMediator _mediator;

    public DoctorsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("dashboard")]
    [Authorize]
    public async Task<IActionResult> GetDashboard(CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var result = await _mediator.Send(new GetDoctorDashboardQuery { UserId = userId }, cancellationToken);
        return Ok(result);
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> SearchDoctors([FromQuery] SearchDoctorsQuery query, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(query, cancellationToken);
        return Ok(result);
    }

    [HttpGet("top-rated")]
    [AllowAnonymous]
    public async Task<IActionResult> GetTopRatedDoctors([FromQuery] GetTopRatedDoctorsQuery query, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(query, cancellationToken);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetById([FromRoute] Guid id, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetDoctorByIdQuery { DoctorId = id }, cancellationToken);
        return Ok(result);
    }

    [HttpGet("{id:guid}/availability")]
    [AllowAnonymous]
    public async Task<IActionResult> GetAvailability([FromRoute] Guid id, [FromQuery] DateOnly? date, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetDoctorAvailabilityQuery
        {
            DoctorId = id,
            Date = date
        }, cancellationToken);
        return Ok(result);
    }

    [HttpGet("{id:guid}/weekly-schedule")]
    [AllowAnonymous]
    public async Task<IActionResult> GetWeeklySchedule(
        [FromRoute] Guid id, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetDoctorWeeklyScheduleQuery(id), cancellationToken);
        return Ok(result);
    }

    [HttpPut("profile")]
    [Authorize]
    public async Task<IActionResult> UpdateOwnProfile([FromBody] UpdateOwnDoctorProfileCommand request, CancellationToken cancellationToken)
    {
        request.UserId = UserContext.GetRequiredUserId(User);
        request.Role = UserContext.GetRequiredRole(User);
        var result = await _mediator.Send(request, cancellationToken);
        return Ok(result);
    }

    [HttpGet("me/status")]
    [Authorize]
    public async Task<IActionResult> GetMyStatus(CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var result = await _mediator.Send(new GetMyStatusQuery { UserId = userId }, cancellationToken);
        return Ok(result);
    }

    [HttpGet("me/documents")]
    [Authorize]
    public async Task<IActionResult> GetMyDocuments(CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var result = await _mediator.Send(new GetMyDocumentsQuery { UserId = userId }, cancellationToken);
        return Ok(result);
    }

    [HttpGet("me/payment-info")]
    [Authorize]
    public async Task<IActionResult> GetPaymentInfo(CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var role = UserContext.GetRequiredRole(User);
        var result = await _mediator.Send(new GetPaymentInfoQuery { UserId = userId, Role = role }, cancellationToken);
        return Ok(result);
    }

    [HttpPut("me/payment-info")]
    [Authorize]
    public async Task<IActionResult> SavePaymentInfo([FromBody] SavePaymentInfoCommand command, CancellationToken cancellationToken)
    {
        command.UserId = UserContext.GetRequiredUserId(User);
        command.Role = UserContext.GetRequiredRole(User);
        var result = await _mediator.Send(command, cancellationToken);
        return Ok(result);
    }
}

