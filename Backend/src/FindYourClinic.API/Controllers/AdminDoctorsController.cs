using FindYourClinic.API.Features.DoctorVerification.GetPendingDoctors;
using FindYourClinic.API.Features.DoctorVerification.ReviewDoctor;
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
        {
            return Unauthorized();
        }

        var command = new ApproveDoctorCommand
        {
            DoctorId = doctorId,
            AdminId = parsedAdminId
        };

        var result = await _mediator.Send(command);
        return Ok(result);
    }

    [HttpPost("{doctorId:guid}/reject")]
    public async Task<IActionResult> RejectDoctor([FromRoute] Guid doctorId, [FromBody] RejectDoctorRequest request)
    {
        var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(adminId) || !Guid.TryParse(adminId, out var parsedAdminId))
        {
            return Unauthorized();
        }

        var command = new RejectDoctorCommand
        {
            DoctorId = doctorId,
            AdminId = parsedAdminId,
            Reason = request.Reason
        };

        var result = await _mediator.Send(command);
        return Ok(result);
    }
}

public class RejectDoctorRequest
{
    public string Reason { get; set; } = string.Empty;
}
