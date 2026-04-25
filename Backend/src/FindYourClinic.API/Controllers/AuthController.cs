using FindYourClinic.API.Features.Auth.ForgotPassword;
using FindYourClinic.API.Features.Auth.GoogleLogin;
using FindYourClinic.API.Features.Auth.Login;
using FindYourClinic.API.Features.Auth.RefreshToken;
using FindYourClinic.API.Features.Auth.Register;
using FindYourClinic.API.Features.Auth.ResetPassword;
using FindYourClinic.API.Features.DoctorVerification.SubmitDocuments;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IMediator _mediator;

    public AuthController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<IActionResult> Register([FromBody] RegisterCommand command)
    {
        var result = await _mediator.Send(command);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginCommand command)
    {
        var result = await _mediator.Send(command);
        return result.Success ? Ok(result) : Unauthorized(result);
    }

    [HttpPost("google")]
    [AllowAnonymous]
    public async Task<IActionResult> Google([FromBody] GoogleLoginCommand command)
    {
        var result = await _mediator.Send(command);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpPost("doctor/upload-documents")]
    [Authorize(Policy = "DoctorOrPendingDoctor")]
    public async Task<IActionResult> UploadDocuments([FromForm] List<IFormFile> files, [FromForm] List<string> documentTypes)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId) || !Guid.TryParse(userId, out var doctorUserId))
        {
            return Unauthorized();
        }

        var command = new SubmitDocumentsCommand
        {
            DoctorUserId = doctorUserId,
            Files = files,
            DocumentTypes = documentTypes
        };

        var result = await _mediator.Send(command);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordCommand command)
    {
        var result = await _mediator.Send(command);
        return Ok(result);
    }

    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordCommand command)
    {
        var result = await _mediator.Send(command);
        return Ok(result);
    }

    [HttpPost("refresh-token")]
    [AllowAnonymous]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenCommand command)
    {
        var result = await _mediator.Send(command);
        return result.Success ? Ok(result) : Unauthorized(result);
    }
}
