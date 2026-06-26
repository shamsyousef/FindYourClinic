using FluentValidation;

namespace FindYourClinic.API.Features.DoctorAvailability.CreateAvailability;

public class CreateAvailabilityCommandValidator : AbstractValidator<CreateAvailabilityCommand>
{
    public CreateAvailabilityCommandValidator()
    {
        RuleFor(x => x.UserId).NotEmpty();
        RuleFor(x => x.StartTime)
            .LessThan(x => x.EndTime)
            .WithMessage("START_TIME_MUST_BE_BEFORE_END_TIME");
    }
}
