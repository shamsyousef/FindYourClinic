using FindYourClinic.API.Common;
using FindYourClinic.API.Features.Users.GetPatientProfileForDoctor;
using FindYourClinic.API.Features.Users.GetProfile;
using FindYourClinic.API.Features.Users.UpdateProfile;
using FindYourClinic.API.Features.Users.UpdateProfileImage;
using FindYourClinic.API.Localization;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IMediator _mediator;

    public UsersController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId) || !Guid.TryParse(userId, out var parsedUserId))
            return Unauthorized();

        var result = await _mediator.Send(new GetProfileQuery { UserId = parsedUserId });
        return Ok(result);
    }

    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId) || !Guid.TryParse(userId, out var parsedUserId))
            return Unauthorized();

        var result = await _mediator.Send(new UpdateProfileCommand
        {
            UserId = parsedUserId,
            FirstName = request.FirstName,
            LastName = request.LastName,
            PhoneNumber = request.PhoneNumber,
            DateOfBirth = request.DateOfBirth,
            Gender = request.Gender,
            BloodType = request.BloodType,
            Address = request.Address,
            EmergencyContactName = request.EmergencyContactName,
            EmergencyContactPhone = request.EmergencyContactPhone,
        });

        return this.WriteFromResult(result);
    }

    [HttpGet("patient/{patientId:guid}")]
    public async Task<IActionResult> GetPatientProfileForDoctor([FromRoute] Guid patientId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetPatientProfileForDoctorQuery
        {
            DoctorUserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User),
            PatientId = patientId
        }, cancellationToken);
        return Ok(result);
    }

    [HttpPut("profile/image")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UpdateProfileImage([FromForm] IFormFile file)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId) || !Guid.TryParse(userId, out var parsedUserId))
            return Unauthorized();

        var result = await _mediator.Send(new UpdateProfileImageCommand
        {
            UserId = parsedUserId,
            File = file
        });

        return this.WriteFromResult(result);
    }

    [HttpPost("request-deletion")]
    public async Task<IActionResult> RequestAccountDeletion([FromBody] RequestAccountDeletionRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId) || !Guid.TryParse(userId, out var parsedUserId))
            return Unauthorized();

        var command = new FindYourClinic.API.Features.Users.RequestAccountDeletion.RequestAccountDeletionCommand
        {
            UserId = parsedUserId,
            Password = request.Password
        };

        var result = await _mediator.Send(command);
        return this.WriteFromResult(result);
    }
}

public class RequestAccountDeletionRequest
{
    public string Password { get; set; } = string.Empty;
}

public class UpdateProfileRequest
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public string? Gender { get; set; }
    public string? BloodType { get; set; }
    public string? Address { get; set; }
    public string? EmergencyContactName { get; set; }
    public string? EmergencyContactPhone { get; set; }
}
