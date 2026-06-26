using FluentValidation;

namespace FindYourClinic.API.Features.DoctorAvailability.GetSlots;

public class GetDoctorAvailabilitySlotsQueryValidator : AbstractValidator<GetDoctorAvailabilitySlotsQuery>
{
    public GetDoctorAvailabilitySlotsQueryValidator()
    {
        RuleFor(x => x.DoctorId).NotEmpty();
    }
}
