using FindYourClinic.Domain.Enums;
using FluentValidation;

namespace FindYourClinic.API.Features.Auth.GoogleLogin;

public class GoogleLoginCommandValidator : AbstractValidator<GoogleLoginCommand>
{
    public GoogleLoginCommandValidator()
    {
        RuleFor(x => x.IdToken).NotEmpty();
        RuleFor(x => x.Role)
            .Must(role => string.IsNullOrWhiteSpace(role) || Enum.TryParse<UserRole>(role, true, out _))
            .WithMessage("Role must be Patient or Doctor.");
    }
}
