using FindYourClinic.Domain.Enums;
using FluentValidation;

namespace FindYourClinic.API.Features.Auth.Register;

public class RegisterCommandValidator : AbstractValidator<RegisterCommand>
{
    public RegisterCommandValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
        RuleFor(x => x.Password).NotEmpty().MinimumLength(8);
        RuleFor(x => x.Role)
            .NotEmpty()
            .Must(x => Enum.TryParse<UserRole>(x, true, out _))
            .WithMessage("ROLE_MUST_BE_DOCTOR_OR_PATIENT");

        When(x => x.Role.Equals(UserRole.Patient.ToString(), StringComparison.OrdinalIgnoreCase), () =>
        {
            RuleFor(x => x.FirstName).NotEmpty().MaximumLength(100);
            RuleFor(x => x.LastName).NotEmpty().MaximumLength(100);
        });

        When(x => x.Role.Equals(UserRole.Doctor.ToString(), StringComparison.OrdinalIgnoreCase), () =>
        {
            RuleFor(x => x.FullName).NotEmpty().MaximumLength(200);
            RuleFor(x => x.SpecialtyId).NotNull();
        });
    }
}
