using FluentValidation;

namespace FindYourClinic.API.Features.DoctorVerification.ReviewDoctor;

public class RejectDoctorCommandValidator : AbstractValidator<RejectDoctorCommand>
{
    public RejectDoctorCommandValidator()
    {
        RuleFor(x => x.DoctorId).NotEmpty();
        RuleFor(x => x.AdminId).NotEmpty();
        RuleFor(x => x.Reason).NotEmpty().MaximumLength(1000);
    }
}
