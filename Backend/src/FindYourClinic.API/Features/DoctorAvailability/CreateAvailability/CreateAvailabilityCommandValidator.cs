using FluentValidation;

namespace FindYourClinic.API.Features.DoctorAvailability.CreateAvailability;

public class CreateAvailabilityCommandValidator : AbstractValidator<CreateAvailabilityCommand>
{
    public CreateAvailabilityCommandValidator()
    {
        RuleFor(x => x.UserId).NotEmpty();
        RuleFor(x => x.StartTime)
            .LessThan(x => x.EndTime)
            .WithMessage("Start time must be before end time.");
    }
}
