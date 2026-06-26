using FluentValidation;

namespace FindYourClinic.API.Features.DoctorVerification.ReviewDoctor;

public class ApproveDoctorCommandValidator : AbstractValidator<ApproveDoctorCommand>
{
    public ApproveDoctorCommandValidator()
    {
        RuleFor(x => x.DoctorId).NotEmpty();
        RuleFor(x => x.AdminId).NotEmpty();
    }
}
