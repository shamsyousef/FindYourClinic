using FindYourClinic.API.Common;
using FindYourClinic.API.Features.Auth.ChangePassword;
using FindYourClinic.API.Features.Auth.ForgotPassword;
using FindYourClinic.API.Features.Auth.GoogleLogin;
using FindYourClinic.API.Features.Auth.Login;
using FindYourClinic.API.Features.Auth.RefreshToken;
using FindYourClinic.API.Features.Auth.Register;
using FindYourClinic.API.Features.Auth.ResetPassword;
using FindYourClinic.API.Features.DoctorVerification.SubmitDocuments;
using FindYourClinic.API.Localization;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
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
    [EnableRateLimiting("auth_normal")]
    public async Task<IActionResult> Register([FromBody] RegisterCommand command)
    {
        var result = await _mediator.Send(command);
        return this.WriteFromResult(result); ;
    }

    [HttpPost("login")]
    [AllowAnonymous]
    [EnableRateLimiting("auth_normal")]
    public async Task<IActionResult> Login([FromBody] LoginCommand command)
    {
        var result = await _mediator.Send(command);
        return this.WriteFromResult(result);
    }

    [HttpPost("google")]
    [AllowAnonymous]
    public async Task<IActionResult> Google([FromBody] GoogleLoginCommand command)
    {
        var result = await _mediator.Send(command);
        return this.WriteFromResult(result); 
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
        return this.WriteFromResult(result); 
    }

    [HttpPost("forgot-password")]
    [AllowAnonymous]
    [EnableRateLimiting("auth_strict")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordCommand command)
    {
        var result = await _mediator.Send(command);
        return this.WriteFromResult(result);
    }

    [HttpPost("reset-password")]
    [AllowAnonymous]
    [EnableRateLimiting("auth_strict")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordCommand command)
    {
        var result = await _mediator.Send(command);
        return this.WriteFromResult(result);
    }

    [HttpPost("change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordCommand command)
    {
        command.UserId = UserContext.GetRequiredUserId(User);
        var result = await _mediator.Send(command);
        return this.WriteFromResult(result);
    }

    [HttpPost("refresh-token")]
    [AllowAnonymous]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenCommand command)
    {
        var result = await _mediator.Send(command);
        return this.WriteFromResult(result);
    }

    [HttpGet("deep-link")]
    [AllowAnonymous]
    public IActionResult DeepLinkRedirect([FromQuery] string url)
    {
        if (string.IsNullOrWhiteSpace(url))
        {
            return BadRequest("URL is required.");
        }

        var html = $@"
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset=""utf-8"">
                <title>Redirecting...</title>
                <meta name=""viewport"" content=""width=device-width, initial-scale=1"">
                <style>
                    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background-color: #f8f9fa; color: #333; }}
                    .container {{ text-align: center; padding: 2rem; background: white; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }}
                    h1 {{ margin-top: 0; color: #0d6efd; }}
                    p {{ margin-bottom: 1.5rem; }}
                    .btn {{ display: inline-block; padding: 10px 20px; background-color: #0d6efd; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; }}
                </style>
            </head>
            <body>
                <div class=""container"">
                    <h1>Opening App...</h1>
                    <p>If you are not automatically redirected, please click the button below.</p>
                    <a href=""{url}"" class=""btn"">Open App</a>
                </div>
                <script>
                    window.location.href = '{url}';
                </script>
            </body>
            </html>";
        return Content(html, "text/html");
    }
}
