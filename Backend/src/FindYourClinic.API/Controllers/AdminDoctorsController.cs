using FindYourClinic.API.Features.Admin.GetAllDoctors;
using FindYourClinic.API.Features.Admin.ToggleDoctorActive;
using FindYourClinic.API.Features.DoctorVerification.GetPendingDoctors;
using FindYourClinic.API.Features.DoctorVerification.ReviewDoctor;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Services;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/admin/doctors")]
[Authorize(Policy = "AdminOnly")]
public class AdminDoctorsController : ControllerBase
{
    private readonly IMediator _mediator;

    public AdminDoctorsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet]
    public async Task<IActionResult> GetAllDoctors([FromQuery] string? status, CancellationToken cancellationToken)
    {
        DoctorStatus? parsedStatus = status switch
        {
            "Pending" => DoctorStatus.PendingReview,
            "Approved" => DoctorStatus.Approved,
            "Rejected" => DoctorStatus.Rejected,
            _ => null
        };

        var result = await _mediator.Send(new GetAllDoctorsQuery(parsedStatus), cancellationToken);
        return Ok(result);
    }

    [HttpGet("pending")]
    public async Task<IActionResult> GetPendingDoctors()
    {
        var result = await _mediator.Send(new GetPendingDoctorsQuery());
        return Ok(result);
    }

    [HttpPost("{doctorId:guid}/approve")]
    public async Task<IActionResult> ApproveDoctor([FromRoute] Guid doctorId)
    {
        var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(adminId) || !Guid.TryParse(adminId, out var parsedAdminId))
            return Unauthorized();

        var command = new ApproveDoctorCommand { DoctorId = doctorId, AdminId = parsedAdminId };
        var result = await _mediator.Send(command);
        return Ok(result);
    }

    [HttpPost("{doctorId:guid}/reject")]
    public async Task<IActionResult> RejectDoctor([FromRoute] Guid doctorId, [FromBody] RejectDoctorRequest request)
    {
        var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(adminId) || !Guid.TryParse(adminId, out var parsedAdminId))
            return Unauthorized();

        var command = new RejectDoctorCommand { DoctorId = doctorId, AdminId = parsedAdminId, Reason = request.Reason };
        var result = await _mediator.Send(command);
        return Ok(result);
    }

    [HttpPost("{doctorId:guid}/toggle-active")]
    public async Task<IActionResult> ToggleDoctorActive([FromRoute] Guid doctorId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new ToggleDoctorActiveCommand(doctorId), cancellationToken);
        return Ok(result);
    }

    [HttpPost("{doctorId:guid}/request-availability")]
    public async Task<IActionResult> RequestDoctorAvailability(
        [FromRoute] Guid doctorId,
        [FromServices] FindYourClinic.Infrastructure.Persistence.ApplicationDbContext dbContext,
        [FromServices] INotificationService notificationService,
        CancellationToken cancellationToken)
    {
        var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(adminId) || !Guid.TryParse(adminId, out _))
            return Unauthorized();

        var doctor = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.FirstOrDefaultAsync(
            dbContext.Users,
            x => x.Id == doctorId && x.Role == FindYourClinic.Domain.Enums.UserRole.Doctor,
            cancellationToken);

        if (doctor == null)
            return NotFound(FindYourClinic.Domain.Common.ApiResponse<object>.Fail("Doctor not found."));

        await notificationService.SendToUserAsync(
            doctorId,
            "Availability Update Needed",
            "Please update your schedule and add availability slots so patients can book appointments with you.",
            new Dictionary<string, string> { ["type"] = "AvailabilityRequest" },
            cancellationToken);

        return Ok(FindYourClinic.Domain.Common.ApiResponse<object>.Ok(null, "Availability request sent to doctor."));
    }
}

public class RejectDoctorRequest
{
    public string Reason { get; set; } = string.Empty;
}
