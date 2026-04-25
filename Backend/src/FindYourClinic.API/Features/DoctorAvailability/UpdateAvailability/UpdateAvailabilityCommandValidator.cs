using FluentValidation;

namespace FindYourClinic.API.Features.DoctorAvailability.UpdateAvailability;

public class UpdateAvailabilityCommandValidator : AbstractValidator<UpdateAvailabilityCommand>
{
    public UpdateAvailabilityCommandValidator()
    {
        RuleFor(x => x.AvailabilityId).NotEmpty();
        RuleFor(x => x.UserId).NotEmpty();
        RuleFor(x => x.StartTime)
            .LessThan(x => x.EndTime)
            .WithMessage("Start time must be before end time.");
    }
}
