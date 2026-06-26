using Ardalis.Result;
using Microsoft.AspNetCore.Mvc;
using FluentValidation;
using FindYourClinic.API.Localization;
using FindYourClinic.Domain.Exceptions;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/test-localization")]
public class LocalizationTestController : ControllerBase
{
    [HttpGet("success")]
    public IActionResult GetSuccess()
    {
        var result = Result.Success(new { CourseId = 42, Name = ".NET 10" }, "COURSE_UPDATED_SUCCESS");
        return this.WriteFromResult(result);
    }

    [HttpGet("not-found")]
    public IActionResult GetNotFound()
    {
        var result = Result.NotFound("COURSE_NOT_FOUND");
        return this.WriteFromResult(result);
    }

    [HttpGet("validation")]
    public IActionResult GetValidation()
    {
        var result = Result.Invalid(new ValidationError
        {
            Identifier = "Email",
            ErrorMessage = "EMAIL_REQUIRED"
        });
        return this.WriteFromResult(result);
    }

    [HttpGet("unauthorized")]
    public IActionResult GetUnauthorized()
    {
        var result = Result.Unauthorized();
        return this.WriteFromResult(result);
    }

    [HttpGet("forbidden")]
    public IActionResult GetForbidden()
    {
        var result = Result.Forbidden();
        return this.WriteFromResult(result);
    }

    [HttpGet("conflict")]
    public IActionResult GetConflict()
    {
        var result = Result.Conflict("CONFLICT");
        return this.WriteFromResult(result);
    }

    [HttpGet("error")]
    public IActionResult GetError()
    {
        var result = Result.Error("BUSINESS_RULE");
        return this.WriteFromResult(result);
    }

    [HttpGet("critical-error")]
    public IActionResult GetCriticalError()
    {
        var result = Result.CriticalError("INTERNAL_ERROR");
        return this.WriteFromResult(result);
    }

    [HttpPost("fluent-validation")]
    public async Task<IActionResult> TestFluentValidation([FromBody] TestEmailRequest request, [FromServices] IValidator<TestEmailRequest> validator)
    {
        var validationResult = await validator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors);
        }
        return Ok(new { success = true, email = request.Email });
    }

    [HttpGet("exception-not-found")]
    public IActionResult TestExceptionNotFound()
    {
        throw new NotFoundException("USER_NOT_FOUND");
    }

    [HttpGet("exception-sentence")]
    public IActionResult TestExceptionSentence()
    {
        throw new BadRequestException("Specialty already exists.");
    }
}

public class TestEmailRequest
{
    public string Email { get; set; } = string.Empty;
}

public class TestEmailRequestValidator : AbstractValidator<TestEmailRequest>
{
    public TestEmailRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty()
            .WithMessage("EMAIL_REQUIRED");
    }
}
