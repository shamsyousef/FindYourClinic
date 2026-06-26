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
using FindYourClinic.API.Features.Admin.DeleteUser;
using FindYourClinic.API.Localization;
using FindYourClinic.Domain.Common;

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
    public async Task<IActionResult> GetAllDoctors(
    [FromQuery] string? status,
    CancellationToken cancellationToken)
    {
        DoctorStatus? parsedStatus = status switch
        {
            "Pending" => DoctorStatus.PendingReview,
            "Approved" => DoctorStatus.Approved,
            "Rejected" => DoctorStatus.Rejected,
            _ => null
        };

        var result = await _mediator.Send(
            new GetAllDoctorsQuery(parsedStatus),
            cancellationToken);

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

        var command = new ApproveDoctorCommand
        {
            DoctorId = doctorId,
            AdminId = parsedAdminId
        };

        var result = await _mediator.Send(command);

        return this.WriteFromResult(result);
    }


    [HttpPost("{doctorId:guid}/reject")]
    public async Task<IActionResult> RejectDoctor(
        [FromRoute] Guid doctorId,
        [FromBody] RejectDoctorRequest request)
    {
        var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrWhiteSpace(adminId) || !Guid.TryParse(adminId, out var parsedAdminId))
            return Unauthorized();

        var command = new RejectDoctorCommand
        {
            DoctorId = doctorId,
            AdminId = parsedAdminId,
            Reason = request.Reason
        };

        var result = await _mediator.Send(command);

        return this.WriteFromResult(result);
    }


    [HttpPost("{doctorId:guid}/toggle-active")]
    public async Task<IActionResult> ToggleDoctorActive(
        [FromRoute] Guid doctorId,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new ToggleDoctorActiveCommand(doctorId),
            cancellationToken);

        return this.WriteFromResult(result);
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


        var doctor = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions
            .FirstOrDefaultAsync(
                dbContext.Users,
                x => x.Id == doctorId &&
                     x.Role == UserRole.Doctor,
                cancellationToken);


        if (doctor == null)
        {
            return this.WriteFromResult(
                ApiResponse<object>.Fail("DOCTOR_NOT_FOUND")
            );
        }


        await notificationService.SendToUserAsync(
            doctorId,
            "AVAILABILITY_UPDATE_NEEDED",
            "PLEASE_UPDATE_AVAILABILITY",
            new Dictionary<string, string>
            {
                ["type"] = "AvailabilityRequest"
            },
            cancellationToken);


        return this.WriteFromResult(
            ApiResponse<object>.Ok(
                null,
                "AVAILABILITY_REQUEST_SENT_TO_DOCTOR"
            )
        );
    }


    [HttpPost("{doctorId:guid}/pending")]
    public async Task<IActionResult> SetDoctorPending([FromRoute] Guid doctorId)
    {
        var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrWhiteSpace(adminId) || !Guid.TryParse(adminId, out var parsedAdminId))
            return Unauthorized();


        var command = new SetDoctorPendingCommand
        {
            DoctorId = doctorId,
            AdminId = parsedAdminId
        };


        var result = await _mediator.Send(command);

        return this.WriteFromResult(result);
    }


    [HttpDelete("{doctorId:guid}")]
    public async Task<IActionResult> DeleteDoctor(
        [FromRoute] Guid doctorId,
        [FromBody] DeleteDoctorRequest request)
    {
        var command = new FindYourClinic.API.Features.Admin.DeleteDoctor.DeleteDoctorCommand
        {
            DoctorId = doctorId,
            Reason = request.Reason
        };


        var result = await _mediator.Send(command);

        return this.WriteFromResult(result);
    }


    [HttpDelete("{userId:guid}")]
    public async Task<IActionResult> DeleteUser(
        [FromRoute] Guid userId,
        [FromBody] DeleteUserRequest request,
        CancellationToken cancellationToken)
    {
        var command = new DeleteUserCommand
        {
            UserId = userId,
            Reason = request.Reason
        };


        var result = await _mediator.Send(command, cancellationToken);

        return this.WriteFromResult(result);
    }
}


public class RejectDoctorRequest
{
    public string Reason { get; set; } = string.Empty;
}


public class DeleteDoctorRequest
{
    public string Reason { get; set; } = string.Empty;
}


public class DeleteUserRequest
{
    public string Reason { get; set; } = string.Empty;
}